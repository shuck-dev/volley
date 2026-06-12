# LFS proxy architecture

Implementation record for SH-489, standing up the R2-backed Git LFS pipeline the
[asset-versioning spike](2026-06-11-asset-versioning-spike.md) decided. The spike chose the backend
(Cloudflare R2 behind an LFS proxy); this record fixes how the proxy is built and captures the live
infra it runs on.

## Proxy: a wrangler Worker with an R2 binding

The spike named the off-the-shelf `git-lfs-s3-proxy` (a Cloudflare Pages deploy that bakes the R2
credentials into each client's `.lfsconfig` URL). The build instead uses a **standalone wrangler
Worker with a native R2 binding**, in its own repo `volley-lfs-proxy`, matching the existing
`linear-mcp` and `nano-banana-mcp` Workers. Two reasons carry the choice: it holds the R2 keys as
Worker secrets, so the write credential stays off every contributor's `.lfsconfig` (the ticket's hard
requirement), and it deploys the way the studio already deploys Workers.

The Worker implements the Git LFS batch API and presigns S3-compatible R2 URLs, so object bytes
stream directly to and from R2 and never pass through the Worker (whose request body caps at 100MB,
below a single large asset). This follows the FlyByWire Simulations R2 LFS Worker pattern.

Three keys separate read from write at the Worker layer, each carried as a Worker secret:

| Key | Grants | Held by |
|---|---|---|
| `DOWNLOAD_KEY` | download, list | published openly; CI, every cloner |
| `UPLOAD_KEY` | download and upload | studio only, given out on request |

The LFS `basic` transfer with presigned PUT URLs needs no separate verify action, so the Worker
carries only the two keys above. The `UPLOAD_KEY` is never published or stored in a repo file; a studio
member who needs to push art asks for it.

## The download key is public; the Worker is the guard

The audience for fetching `assets/` is anyone who clones, so the `DOWNLOAD_KEY` is treated as a
published value, printed in CONTRIBUTING and carried in `.lfsconfig.example`. Its openness is fine
because secrecy is not what protects the bucket: the Worker enforces a rate limit and a per-window
byte cap on the download path, so a key in a scraper's hands still cannot burn the R2 free tier.
CI reads the same key from a `gh` Actions secret (`LFS_DOWNLOAD_KEY`) to keep the workflow file clean,
not because the value is confidential. Only `UPLOAD_KEY` and the R2 Secret Access Key stay truly
secret, as Worker secrets the studio holds.

A reveal-gate page (Turnstile captcha that surfaces the key to a human) and per-contributor token
issuance are possible later hardening if scraping becomes real; they sit behind the same Worker rate
limit and are out of scope here.

## Three tracks

1. **`volley-lfs-proxy`** (standalone local project): the Worker, `wrangler.jsonc` bound to
   `volley-assets`, the batch handler, vitest suite. **Done and deployed**, verified end to end.
2. **Cloudflare account setup**: **done**. R2 enabled, bucket created, token minted, secrets set.
3. **volley repo wiring** (separate challenge, the remaining work): committed `.gitattributes` tracking
   `assets/**` and `concepts/**`; committed `.lfsconfig` carrying the Worker URL with the published
   download key (so a clone is zero-config); `make concepts`; `concepts/` un-gitignored; an `assets/`
   directory; CONTRIBUTING setup, published key, and rate-limit note.

### CI integration

`test.yml`, `publish.yml`, and `release.yml` each run `godot --headless --import` (Import Project),
which walks the whole tree. Bare LFS pointers under `assets/` would import as garbage, so each workflow
needs, **before its Import Project step**: an `actions/cache` of LFS objects keyed on the pointer-file
hash, then `git lfs pull --include="assets/**"` (assets only, never `concepts/`), authenticated by the
`LFS_DOWNLOAD_KEY` Actions secret. `test.yml` needs this for the same reason as the build workflows: its
import step, not its assertions, is what requires real bytes. Checkout stays SHA-pinned; the new steps
follow suit.

## Live infra

Account `volcanoem@gmail.com`, ID `effe9646943c4ead286bad9d06e16e74`.

- Worker deployed at `https://volley-lfs-proxy.volcanoem.workers.dev`, verified end to end (auth matrix,
  presigned signing, R2 round trip).
- R2 bucket `volley-assets`, region WEUR, Standard storage class.
- S3 endpoint `https://effe9646943c4ead286bad9d06e16e74.r2.cloudflarestorage.com`.
- R2 API token: Account token, Object Read and Write, scoped to `volley-assets`, no expiry. Access Key
  ID `9d7317e3a2fb0ce6dd2f3f5e4a0e217a`. The Secret Access Key is held by Josh and enters the Worker
  through `wrangler secret put`; it is never committed.

The read and write split that contributors see is enforced by the Worker's `DOWNLOAD_KEY` and
`UPLOAD_KEY`; the single R2 token behind them carries object read and write because the Worker presigns
both GET and PUT.
