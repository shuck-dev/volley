# Asset versioning spike (SH-461)

Decision record for how Volley versions binary assets. Closes the SH-461 spike; blocks SH-482 (Sam
Level-of-Detail). Implementation is follow-up work, not part of this spike.

## Decision

Store binary assets on **Cloudflare R2**, fronted by a **Git LFS proxy** (`git-lfs-s3-proxy` on a
Cloudflare Worker). One backend, two directory-keyed classes. The repo holds LFS pointers, never bytes.

## Two classes, split by directory

| Class | Directory | Needed to run the game? | Fetched by default? |
|---|---|---|---|
| Assets | `assets/` (sprites, audio, imported game content) | Yes | Yes, on build/run/CI |
| Concepts | `concepts/` (concept art, reference, PSDs) | No | No, opt-in only |

- **Assets** pull transparently via `git lfs pull` on the run/build path. CI fetches them as a build step.
- **Concepts** are excluded from the default fetch; pulled only on demand with
  `git lfs pull --include="concepts/**"` (wrapped as `make concepts`).

A public clone gets pointers and no bytes. A contributor who wants to run the game fetches `assets/`; a
contributor who wants the art additionally fetches `concepts/`. Nobody drags down concept art to build.

## Key tradeoff

One piece of self-hosted infra (a Cloudflare Worker running the LFS proxy) plus a contributor `git-lfs`
install, bought in exchange for **zero clone-bandwidth cost** and **transparent updates** as churny art
iterates. The rejected alternatives:

| Option | Why not |
|---|---|
| Commit binaries directly | Concepts land in history forever; every clone pulls them; fails the "clone stays lean, assets not pulled by default" requirement. |
| GitHub LFS | Bandwidth billed to the repo owner for every public clone (bots included); free tier exhausts fast; documented account-wide LFS disables. Wrong for a public repo. |
| R2 + pointer manifest (no LFS) | Zero infra, but a per-fetch `make assets` step the contributor must remember; stale bytes between fetches. Worse under high churn, which is the stated horizon. |

The proxy beats the plain manifest specifically because assets are **soon and churny**: per-fetch friction
compounds with churn, one-time infra setup does not.

## Size gate

Blocks a large binary from entering plain git history, regardless of backend.

- **Local:** `pre-commit` framework `check-added-large-files` (auto-skips LFS-tracked files), threshold
  ~500KB, keyed so `assets/` and `concepts/` route through LFS rather than tripping the gate.
- **Hard gate:** a CI PR check comparing added files against the merge base, failing the PR on any plain
  binary over threshold. Catches contributors who skipped local hook install.
- Both **exclude `.import` sidecars** from the threshold (they are generated config, can be large).

## `.import` policy

Commit the per-asset `.import` sidecars (official Godot guidance: they carry non-default import settings;
ignoring them forces a default reimport on checkout). Accept that engine upgrades churn them. Ignore
`.godot/imported/` (the binary cache).

## Infra

The Cloudflare Worker running the LFS proxy is the chosen infra, on the condition that it stays within
R2 and Worker free-tier usage (10GB R2 storage, Worker free request allowance). If projected usage would
exceed the free tier, revisit before paying: the R2 + manifest fallback (zero always-on infra, per-fetch
friction) is the escape hatch.

## Contributor setup (to document in CONTRIBUTING when implemented)

1. `git lfs install` (once per machine).
2. Clone. Working tree has pointers; `assets/` LFS objects fetch on checkout via the proxy.
3. `make concepts` only if you want the concept art.

## Follow-up (separate ticket, not this spike)

Wire `.lfsconfig` at the proxy, `.gitattributes` LFS-tracking `assets/` and `concepts/`, stand up the
Cloudflare Worker, add the size-gate hook + CI check, un-gitignore `concepts/`, create `assets/`,
document setup in CONTRIBUTING. This unblocks SH-482.
