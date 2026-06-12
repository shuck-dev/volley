# LFS proxy architecture

Implementation record for SH-489, standing up the R2-backed Git LFS pipeline the
[asset-versioning spike](2026-06-11-asset-versioning-spike.md) decided. The spike chose the backend
(Cloudflare R2 behind an LFS proxy); this record fixes how the proxy is built, how the bucket stays
free of orphaned bytes, and the live infra it runs on.

## Proxy: a wrangler Worker with an R2 binding

The build uses a standalone wrangler Worker with a native R2 binding, in its own project
`volley-lfs-proxy`, matching the existing `linear-mcp` and `nano-banana-mcp` Workers. The load-bearing
reason is deploy-pattern match: the studio already ships Workers this way, and the Worker holds the R2
keys as Worker secrets so the write credential stays off contributor config. (The off-the-shelf
`git-lfs-s3-proxy` is also a Worker and could hold secrets the same way; the deciding factor is the
existing toolchain, not a credential property.)

The Worker implements the Git LFS batch API and presigns S3-compatible R2 URLs, so object bytes stream
directly to and from R2 and never pass through the Worker (whose request body caps at 100MB, below a
single large asset). This follows the FlyByWire Simulations R2 LFS Worker pattern.

## Three keys

| Key | Grants | Held by |
|---|---|---|
| `DOWNLOAD_KEY` | download from release/ | published; every cloner, CI |
| `UPLOAD_KEY` | upload to preview/, read preview/ | studio and CI; given out on request |
| `PROMOTE_KEY` | promote preview/ to release/ | CI on main only |

The LFS `basic` transfer with presigned PUT URLs needs no verify action. The Worker exposes no list
endpoint, so a key holder can fetch an object whose oid they know but cannot enumerate the bucket.
`UPLOAD_KEY` and `PROMOTE_KEY` live only as Worker secrets; neither is
published or committed. `UPLOAD_KEY` is given to studio members who push art, `PROMOTE_KEY` to CI.

## The download key is public; the Worker guards the tier

Anyone who clones fetches `assets/`, so `DOWNLOAD_KEY` is a published value, printed in CONTRIBUTING.
Secrecy is not the protection: the Worker rate-limits the download path (a fixed window of
`DOWNLOAD_RATE_LIMIT` requests per `DOWNLOAD_RATE_WINDOW_SECONDS` per client IP), so an open key in a
scraper's hands cannot drain the R2 free tier. CI reads the same key from a `gh` Actions secret
(`LFS_DOWNLOAD_KEY`) for a clean workflow file, not for confidentiality.

The rate-limit counter is the one piece that trades strictness for simplicity. It is stored per
window in R2 and read-incremented without a lock, so concurrent requests on one edge can overshoot the
window by up to their concurrency. The accepted worst case is a single-digit multiple of the configured
limit, which the R2 free tier absorbs; if real abuse appears, the counter moves to a Durable Object or
Workers KV for atomicity. A Turnstile reveal page and per-contributor tokens are possible later
hardening behind the same limit.

## preview/ and release/: orphans cannot accumulate

A naive single-path bucket accumulates orphans: bytes pushed for a PR that never merges sit in R2
forever, referenced by nothing on main. Git LFS has no server-side garbage collection, and deleting
unreferenced objects is hazardous (an object orphaned from main's tip may still be reached by an older
commit or tag, so deleting it breaks that checkout). The pipeline avoids the problem by construction
rather than cleaning up after it, using two R2 prefixes named for the build lifecycle:

- **`preview/<oid>`** holds bytes pushed from a PR branch. Uploads presign here. An R2 lifecycle rule
  expires the `preview/` prefix at **30 days**, so the bytes of an abandoned PR evaporate on their own.
  R2 does this natively; there is no GC script and no history hazard, because only `preview/` is reaped.
- **`release/<oid>`** is the canonical store. Objects arrive only when CI promotes them on merge to
  main. `release/` has no expiry; history references it forever.

Flow:

1. **Upload** (PR work): the Worker presigns a PUT to `preview/<oid>`. Only an `UPLOAD_KEY` holder can
   upload.
2. **Promote** (merge to main): a CI job calls the Worker's `/promote` endpoint, authenticated by a
   distinct `PROMOTE_KEY`. The Worker copies each oid from `preview/` to `release/` using its R2
   binding. The promote job runs only on `push` to `main`, never on a `pull_request` event, so it never
   executes in a fork PR's context and `PROMOTE_KEY` is never exposed to fork-triggered runs. (The repo
   uses no `pull_request_target`, which would otherwise hand a fork PR access to repo secrets.) That
   closes the enforcement chain: `PROMOTE_KEY` is reachable only from a trusted on-main run, so "CI is
   the only writer of `release/`" is enforced, not conventional. Each oid is independent: an
   already-promoted oid is a no-op (idempotent and retry-safe), a missing `preview/` object fails that
   oid, and any failure returns a non-2xx so CI retries.
3. **Download**: the Worker resolves `release/<oid>`. An `UPLOAD_KEY` holder (studio, CI) additionally
   falls back to `preview/<oid>`, so an open PR's CI fetches the assets it just pushed before they are
   promoted. The public `DOWNLOAD_KEY` resolves `release/` only, keeping unreleased `preview/` art off
   the published key.
4. **Cleanup**: the R2 lifecycle rule expires stale `preview/` objects. Automatic, server-side.

**Parked-PR policy.** A PR open past the 30-day window has its `preview/` bytes reaped, and its next CI
run would fail the LFS fetch. The recovery is a re-push of the branch, which re-uploads the objects to
`preview/`. The window is set comfortably longer than a healthy PR lifetime, so reaping a still-open
PR's bytes signals a stale PR, and the re-push is the explicit revive.

This maps onto the existing CI split (`publish.yml` is Preview Release, `release.yml` is Live Release):
the bucket prefix is the build-lifecycle stage. `release/` only ever holds merged content, so orphans
are structurally impossible there.

## What goes into LFS: track by path, gate by size

Git LFS routes a file to LFS when its path matches an LFS pattern in `.gitattributes` at `git add`
time. It cannot route by size; size is invisible to the filter. The asset policy ("large files go to
LFS, small files stay in plain git") is therefore expressed as two cooperating mechanisms:

- **`.gitattributes` tracks the large-by-nature paths** (concept art wholesale, and the large asset
  formats: source art, audio, sprite sheets). Because `.gitattributes` is committed and git honours it
  on every machine with no setup, it protects even a cloner who never installed the local hooks. This
  is the cloner-proof routing.
- **The size gate (SH-488) is the backstop.** Its local pre-commit hook catches a large plain file
  early, and its CI check fails the PR if a plain binary over 500KB reaches the diff. The CI half is
  what protects against a cloner who skipped the local hook: the local hook is a convenience, the PR
  gate is the guarantee.

The small assets already committed to git history (a few KB each) stay as plain bytes; tracking is
going-forward, with no history rewrite. The exact `.gitattributes` patterns are settled in the wiring
challenge.

## CI integration

`test.yml`, `publish.yml`, and `release.yml` each run `godot --headless --import` (Import Project).
The repo's Leak gate fails the test run on a standalone `Failed loading resource` error, and tested
scenes reference files under `assets/`, so a checkout with bare LFS pointers under `assets/` would fail
the run. Each workflow therefore needs, before its Import Project step: an `actions/cache` of LFS
objects keyed on the pointer-file hash, then `git lfs pull --include="assets/**"` (assets only, never
`concepts/`), authenticated by the `LFS_DOWNLOAD_KEY` Actions secret. `release.yml` and `publish.yml`
additionally run the promote step on merge to main. New steps stay SHA-pinned, matching checkout.

## Three tracks

1. **`volley-lfs-proxy`** (standalone project): the Worker, `wrangler.jsonc` bound to `volley-assets`,
   the batch handler, the `preview/`/`release/` split, the `/promote` endpoint, the rate limit, and the
   vitest suite. Built and tested; redeploy with the `PROMOTE_KEY` secret lands the prefix split live.
2. **Cloudflare account setup**: R2 enabled, bucket created, token minted, secrets set. The `preview/`
   30-day lifecycle rule is added with `wrangler r2 bucket lifecycle`.
3. **volley repo wiring**: `.gitattributes` tracking the large paths, committed `.lfsconfig` with the
   published download key, `make concepts`, `concepts/` un-gitignored, the CI fetch-and-cache steps, the
   promote-on-merge step, and CONTRIBUTING setup.

## Live infra

Account `volcanoem@gmail.com`, ID `effe9646943c4ead286bad9d06e16e74`.

- Worker deployed at `https://volley-lfs-proxy.volcanoem.workers.dev`, verified end to end (auth
  matrix, presigned signing, R2 round trip). The `preview/`/`release/` build is tested and lands live on
  the next deploy with the `PROMOTE_KEY` secret.
- R2 bucket `volley-assets`, region WEUR, Standard storage class.
- S3 endpoint `https://effe9646943c4ead286bad9d06e16e74.r2.cloudflarestorage.com`.
- R2 API token: Account token, Object Read and Write, scoped to `volley-assets`, no expiry. Its Access
  Key ID lives in the Worker's `wrangler.jsonc` vars; its Secret Access Key is held by Josh and set as a
  Worker secret, never committed.
