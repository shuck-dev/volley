# Release playbook

How Shuck ships a release. Agents read this only when Josh asks for a release.

**Cadence: weekly, Tuesdays around 09:00 UK time.** Josh cuts the real release. Mid-week hotfix releases happen only when a shipped release is broken. Work that lands after Tuesday rides to the following week's tag.

## Steps

1. **Version format `super.major.minor`** (e.g. `v0.2.0`). Bump `major` for a significant batch of work, `super` only at v1 launch, `minor` for small fixes on top of an existing major.
2. **Draft with `gh release create <tag> --draft`** — never publish. Josh publishes after reviewing.
3. **Draft notes are narrative, not a file-level changelog.** Open with what the release represents, then a grouped "What changed" summary, then:
   - **Play**: itch.io page link first; build-from-source note second.
   - **Save warning**: if save format changed since the previous release, point the player at the in-game **Clear Save** button (dev panel), not filesystem paths. This project deliberately does not ship save-format migrations.
   - **Thanks**: short line to contributors.
   - **Full changelog link**: `/compare/v<old>...v<new>`.
4. **Draft URLs show `untagged-<hash>`** until publish; the tag is created on publish. Expected, not a bug.

## Pre-publish handoff checklist

- All PRs related to the release are merged; no staleness on main.
- CI on `main` at the release SHA is green.
- Workflow Godot version matches the editor version the presets were authored against (grep `GODOT_VERSION:` across `.github/workflows/`).
- Manual itch-side state confirmed (or flagged for Josh): the `html5-preview` upload still has "play in browser" ticked.
- Draft title and body reflect the current shape of the release (re-read the `compare/` link to catch late additions).

## Release workflow

`.github/workflows/release.yml` fires on publish. It exports the Linux preset and pushes to `Speedyoshi/volley:linux` with `--userversion <tag>`. Preview continues to mirror `main` on `html5-preview` independently.

## Release candidates

For risky or pipeline-touching releases, cut a `-rc.N` prerelease first (`gh release create v0.2.0-rc.1 --draft --prerelease`). GitHub hides prereleases from "latest"; itch treats the userversion as a normal archived build. If the rc ships clean, delete the rc release and its tag once the real release is published so the Releases page stays tidy:

```
gh release delete v0.2.0-rc.1 --yes --cleanup-tag
```

If the rc fails, iterate (`rc.2`, `rc.3`) until green, then publish the real tag. Never leave `rc.N` tags hanging after the corresponding real release is live.
