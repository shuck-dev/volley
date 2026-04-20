# Parallel Processing Coordination: Volley!

Live scratchpad for parallel agent work on individual Linear tickets. One agent per ticket. Read this before starting, and log progress in the Activity Log at the bottom (see "How to use this doc" for cadence).

---

## How to use this doc

1. **Claim a ticket.** Every branch that lands on main must carry a Linear ticket in its name. If the work is a chore/infra task with no existing SH-N, file one first via `./scripts/dev/new-ticket.sh "<short title>"` (creates Backlog / Feature / assigned to Josh / estimate 0, auto-slotted into the active cycle, per CLAUDE.md). The helper prints `SH-N` on stdout; compose it into the branch name, e.g. `git checkout -b sh-$(echo $TICKET | sed 's/SH-//')-short-desc` or plainly `git checkout -b sh-127-auto-ticket-chore`. Then add a row to the Active table with agent name, ticket ID, branch, and start timestamp. Commit the claim on the branch so it ships with the PR, not on main. No more `chore/<slug>` branches: everything that lands on main is SH-ticketed. **Label taxonomy lives in `designs/process/labels.md`** (discipline × tier). Default for chore/infra is `feature` (tech-produce); pick a different label only if the work is a `spike`, `bug`, `asset`, `revision`, `draft`, etc. — read labels.md before overriding the default.

   **Cycle placement on pick-up.** Active work lives in the cycle. If you're claiming an existing Backlog ticket that has no `cycle` set, move it into the currently active cycle via the Linear MCP: call `mcp__linear__list_cycles` with `teamId` + `isActive: true` to get the active cycle id, then `mcp__linear__save_issue` with `id: <ticket>` and `cycleId: <id>`. New/unclaimed tickets stay cycle-less per the usual Josh convention; pick-up is what triggers the cycle move. If there's no active cycle (gap between cycles), skip the move and leave the ticket cycle-less until the next cycle opens.
2. **Log progress.** Append one line per meaningful step to the Activity Log at the bottom. Keep it terse: `[SH-XX] <agent>: <what happened>`.
3. **Sync before opening, and sync again before any later push.** Before `gh pr create`, run `git fetch origin main && git merge origin/main` into your branch, resolve conflicts, re-run `./scripts/ci/run_gut.sh`, then push. After the PR exists, do the same check whenever you resume work, after a reviewer asks for changes, and before Josh is asked to merge: other PRs may have landed on main and made this branch stale. `git rev-list --count HEAD..origin/main` gives you the "behind by N" count; zero means you're up to date. This catches conflicts locally instead of surfacing them in the PR view for Josh to chase.
4. **Finish.** Move the row from Active to Done, note the commit SHA and PR number. After `gh pr create`, dispatch the **matching specialist reviewers** from `.claude/agents/` in parallel (as background agents), by changed path:
   - `**/*.gd` → `code-quality`, `gdscript-conventions`, `test-coverage`
   - `**/*.tscn` or `**/*.tres` → `godot-scene`
   - diff contains `connect(`, `emit(`, `tree_exit`, or a new autoload → `signals-lifecycle`
   - `.github/**` → `ci-and-workflows`
   - `export_presets.cfg`, `project.godot`, or `**/*.import` → `asset-pipeline`
   - `**/*.md` → `docs-and-writing`

   If zero match, skip review. Each specialist splits findings the same way:
   - **Mechanical fixes** (typos, dead code, obvious bugs, style violations, missing null checks): apply as commits on the PR branch and push.
   - **Everything else**: post as short line-anchored review comments so Josh can mark them Resolved in the Files changed tab. **Follow [Conventional Comments](https://conventionalcomments.org/)**: prefix each with one of `praise:`, `nitpick:`, `suggestion:`, `issue:`, `question:`, `thought:`, `chore:`, `note:` (optionally with decorators like `(non-blocking)`). **Keep it short: one idea per comment, two sentences max.** If it needs more context, open an issue and link to it from the comment. After all matching specialists finish: if every one returned clean, apply the `ai-approved` label (`gh pr edit <N> --add-label ai-approved`). If any comments landed, apply `action-required` instead. Don't post `LGTM` or any other summary comment. Template for line-anchored comments:
     ```
     gh api -X POST repos/shuck-dev/volley/pulls/<N>/comments \
       -f body="..." \
       -f commit_id="<sha of your latest push>" \
       -f path="<file>" \
       -F line=<line> \
       -f side=RIGHT
     ```
   Hand off to Josh only after both have landed. Do not flag review comments in chat; the PR view is the single source of truth.
5. **Re-sync before handoff.** Before reporting the PR to Josh for merge, run `git rev-list --count HEAD..origin/main`. If non-zero, merge `origin/main` in, re-run `./scripts/ci/run_gut.sh`, push. Then report. Don't wait for human approval of the auto-fixes; Josh reviews after.
6. **Block or spin.** If you loop on the same issue twice, escalate to Josh immediately (see Escalation). Do not try a third variant silently.

**Optional: follow-up review.** If Josh asks for another review on an existing PR, dispatch a fresh code-reviewer and post each finding as a line-anchored review comment using the `gh api .../pulls/<N>/comments` template above. If the reviewer returns nothing, post nothing. Do **not** auto-apply fixes; Josh may respond inline or mark comments resolved. Initial review fixes still auto-commit per step 4; only follow-up reviews are comment-only.

---

## Ground rules

- **One ticket, one agent, one branch, one worktree.** Never two agents in the same `.gd`/`.tscn` file at once. Check the Active table's "Files touched" column before starting. Every sub-agent dispatched to modify the repo must use `isolation: "worktree"` on the Agent call, so each lands in its own `git worktree add ../volley-sh-N sh-N-branch` checkout. Sharing the main working tree causes the stash-shuffle failure mode seen when multiple agents edit workflow files or `ai/PARALLEL.md` in parallel. The main tree stays for interactive / single-agent work.
- **Worktree cleanup on merge.** Once a PR is merged, the corresponding worktree and branch are removed: `git worktree remove ../volley-sh-N && git branch -D sh-N-...`. Leaving stale worktrees costs disk and invites later agents to resurrect abandoned changes. Cleanup is the agent's responsibility before reporting the PR as done if the agent is still alive; otherwise Josh or the next orchestrator sweeps periodically with `git worktree list` and `git worktree prune`.
- **Never rebase; merge main in.** To update a branch with main, use `git merge main`, never `git rebase`. If a rebase is genuinely required (rare, e.g. cleaning history before first push), stop and ask Josh first. Josh merges PRs; agents don't.
- **No amending, no force-push.** Add a new commit on top instead of `git commit --amend`. Do not `git push --force` or `--force-with-lease`. Intermediate noise is fine; GitHub's squash-merge collapses it at merge time. Only use amend/force when Josh explicitly asks.
- **Fresh branch after a PR merges.** Never pile more commits onto a branch whose PR already merged (squash-merge retires the branch). Cut a new branch off current `origin/main` for any follow-up work. If you see `remote: Create a pull request for '<branch>'` after `git push` on a branch you thought was live, the remote deleted it — stop and cut a fresh branch.
- **Run `./scripts/ci/run_gut.sh` after every code change.** Iterate until green. Do not invoke lefthook manually; the pre-commit hook fires automatically on `git commit` against staged files. If the commit fails, fix and re-commit.
- **Merge queue serialises main.** GitHub's native merge queue is enabled on `main`: once Josh clicks "Merge when ready", the queue pulls the PR into a short-lived `merge_group` ref, re-runs `lint` and `test` against `main + PR`, and only then fast-forwards main. That replaces the old `auto-update-prs.yml` sweep — do not re-add it, and do not chain any workflow to "on push to main" expecting a post-merge sync step. The pre-PR `git merge origin/main` in rule 3 still matters because it catches conflicts locally; the queue only catches mechanical staleness, not semantic conflicts. The `has-conflicts` label still exists for manual triage, but nothing applies it automatically now.
- **Godot tool discipline**: prefer GodotIQ MCP tools over raw file ops; never delete-and-rebuild scenes; `node_ops` + `save_scene` for `.tscn`.
- **[Conventional Commits](https://www.conventionalcommits.org/)** for commit messages (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `style:`, `perf:`, `ci:`, `build:`, `revert:`). The repo's `commit-msg` hook enforces `[SH-<ticket> ]<type>: <subject>`. Git aliases and helpers in Josh's local shell: `gcb` (`git checkout -b`), `gst`, `gaa`, `gpsup` (`git push -u origin HEAD`). Convenience shell functions for conventional-commit messages: `gcf "msg"` (feat), `gcx` (fix), `gcd` (docs), `gcr` (refactor), `gct` (test), `gch` (chore). All auto-signoff. These are personal environment; public surfaces (PR bodies, commit messages, repo docs) spell out the canonical command. Raw `git commit -s` is fine when a multi-line body is needed.
- **Engineer PRs to merge in any order.** Each PR should stand alone against current main. Combine related changes that share a file rather than splitting them. Avoid "depends on #X" unless the dependency is structural. Josh merges in whatever order suits him; implicit ordering creates friction every time the queue is triaged.
- **Verify, don't assume.** Every change needs evidence: tool output or tests, not "looks correct".

---

## Godot session tiers

Three tiers of Godot access. Pick the lowest tier that answers your question. Higher tiers cost more isolation and, for Tier 2, need Josh's consent.

| Tier | What it covers | Parallelism | Needs an editor? |
|---|---|---|---|
| **0 — Static** | `./scripts/ci/run_gut.sh`, `validate`, `file_context`, `signal_map`, `impact_check`, edits to `.gd`, grep, read | High. N agents in parallel. | No. Headless forks. |
| **1 — Scene edits** | `node_ops`, `build_scene`, `save_scene`, `placement`, `scene_map`, `spatial_audit` | Serial on the live editor, or parallel via git worktrees (each worktree = its own `.godot/` cache and editor). | Yes, per worktree. |
| **2 — Runtime** | `run(play)`, `state_inspect`, `verify_motion`, `screenshot`, `input`, `ui_map`, `perf_snapshot` | Single-agent, exclusive editor. | Yes, exclusive. |

**Default is Tier 0.** Josh's no-playtest rule keeps most work here.

**Tier 1** is fine when scene work is genuinely required. If another agent is at Tier 1 on overlapping files, spawn with `isolation: "worktree"` so each gets its own `.godot/`. First boot of a fresh worktree re-imports the project (~1 minute on this codebase) — plan for it.

**Tier 2 is by request only.** An agent must ask Josh before running the game. Acceptable reasons: reproducing a reported bug that only manifests at runtime, verifying a Tier 1 scene change loads without errors, measuring a performance regression the code review cannot catch. Unacceptable: "double-checking my work", "just to be sure". The no-playtest rule stands by default; exceptions are earned per ticket.

Format for the ask:

```
RUNTIME REQUEST [SH-XX] <agent>: <one-line reason>
  What I'll verify: <concrete claim, e.g. "Martha's bark fires when score crosses 50">
  How I'll verify: <which state_inspect path, or which verify_motion call>
  Why static checks are insufficient: <one sentence>
```

Post it in the Activity Log with the `RUNTIME REQUEST` prefix. Do not `run(play)` until Josh answers.

---

## Escalation to Josh (early, not late)

Escalate the **first** time you hit any of these; circular failure modes are cheap to flag early and expensive to hide:

- **Loop detected**: tried two genuinely different strategies on the same failure. Stop. Do not try a third. Post to Activity Log with `ESCALATE:` prefix and include the failing evidence from both attempts.
- **Scope ambiguity**: the ticket AC is met but you're unsure if the spirit is satisfied, or the ticket touches a system you can't understand from design docs alone.
- **Cross-ticket collision**: your change forces edits in a file another active stream owns.
- **Design gap**: code says one thing, design doc says another, and the ticket doesn't pick a side.
- **External dependency shift**: Godot engine bug, addon regression, API change mid-task.

Escalation format in Activity Log:

```
ESCALATE [SH-XX] <agent>: <one-line summary>
  Tried: <strategy 1> → <evidence>
  Tried: <strategy 2> → <evidence>
  Question: <what you need Josh to decide>
```

---

## Releases

**Cadence: weekly, Tuesdays around 09:00 UK time.** Josh cuts the real release then. Mid-week hotfix releases happen only when a shipped release is broken. Work that lands after Tuesday rides to the following week's tag.


When Josh asks for a release:

1. **Version format is `super.major.minor`** (e.g. `v0.2.0`). Bump `major` for a significant batch of work, `super` only at v1 launch, `minor` for small fixes on top of an existing major.
2. **Draft with `gh release create <tag> --draft`**, never publish. Josh publishes himself once he has reviewed.
3. **Draft notes are narrative, not a file-level changelog.** Open with what the release represents, follow with a grouped "What changed" summary, then:
   - **Play section**: link to the itch.io page first; build-from-source note second.
   - **Save warning**: if the save format changed since the previous release, point the player at the in-game **Clear Save** button (in the dev panel) rather than filesystem paths. This project deliberately does not ship save-format migrations.
   - **Thanks**: short line to contributors.
   - **Full changelog link**: `/compare/v<old>...v<new>`.
4. **Draft release URLs show `untagged-<hash>`** in the path until publish; the git tag is only created on publish. Expected, not a bug.

Pre-publish handoff checklist (agent runs this before telling Josh "ready"):

- All PRs related to the release are merged; no staleness on main.
- CI on `main` at the release SHA is green.
- Workflow Godot version matches the editor version the presets were authored against (grep `GODOT_VERSION:` across `.github/workflows/`).
- Manual itch-side state confirmed (or flagged for Josh): the `html5-preview` upload still has "play in browser" ticked.
- Draft title and body reflect the current shape of the release (re-read the `compare/` link to catch late additions).

Release workflow (`.github/workflows/release.yml`) fires on publish. It exports the Linux preset and pushes to `Speedyoshi/volley:linux` with `--userversion <tag>`. Preview continues to mirror `main` on `html5-preview` independently.

**Release candidates.** For risky or pipeline-touching releases, cut a `-rc.N` prerelease first (`gh release create v0.2.0-rc.1 --draft --prerelease`). GitHub hides prereleases from "latest"; itch treats the userversion as a normal archived build. If the rc ships clean, **delete the rc release and its tag once the real release is published** so the Releases page stays tidy:

```
gh release delete v0.2.0-rc.1 --yes --cleanup-tag
```

If the rc fails, iterate (`rc.2`, `rc.3`) until green, then publish the real tag. Never leave `rc.N` tags hanging around after the corresponding real release is live.

---

## Godot edge cases to watch for

Compatibility traps that have bitten this project or are documented in Godot 4. Check against these before declaring a ticket done:

### Scene / node

- **`@onready` on renamed children silently breaks**: use `@export` for node refs (project rule).
- **Scene root path in `node_ops`**: paths are relative to scene root (`"Sun"` not `"Main/Sun"`).
- **`build_scene` ≤256 nodes per call**: split by parent if you exceed.
- **Delete-and-rebuild is banned**: surgical `node_ops` edits only, even for "just a few tiles".
- **`ClassName.new()` on freshly-written scripts**: class cache is async; use `load("res://path.gd").new()` for scripts touched this session.
- **Tool scripts**: `@tool` scripts run in the editor; `Engine.is_editor_hint()` guards are mandatory for any side-effectful `_ready()`.

### Signals / lifecycle

- **Signal orphans after refactor**: run `signal_map(find="orphans")` as part of QA gate; don't skip.
- **`tree_exiting` vs `tree_exited`**: `tree_exiting` fires before removal (node still valid); `tree_exited` fires after (don't touch the node). Getting this wrong causes freed-instance access.
- **Autoload order matters**: `project.godot` autoloads init top-to-bottom. Current order is `SaveManager`, `ItemManager`, `ProgressionManager`, `ConfigHotReload`. Don't reorder without checking cross-deps.
- **`call_deferred` vs `set_deferred`**: physics/signal callbacks mutating tree state need `call_deferred`, not direct mutation, or you get "parent is busy" errors.

### Physics / CharacterBody / area

- **`move_and_slide` on `CharacterBody2D/3D` mutates `velocity` in place**: read after the call, not before.
- **`Area` signals fire once per overlap pair**: re-entering the same area doesn't re-fire unless monitoring toggled.
- **Layer vs mask asymmetry**: A detects B only if A's mask includes B's layer, not vice versa. Always check both sides.

### Resources / saves

- **`.tres` binary vs text**: text is required for version control diffs; check the resource save format flag.
- **No save backwards-compat shims** (project rule): change the code, not the loader.
- **Resource UIDs**: `res://...` and `uid://...` can diverge after file moves; prefer UIDs for stable refs.

### Input / UI

- **`_input` vs `_unhandled_input`**: UI elements consume input first; gameplay input goes in `_unhandled_input` or it fires during menus.
- **`Control.mouse_filter = STOP` blocks children too**: set PASS on parents of clickable children.
- **Focus stealing**: buttons auto-grab focus on hover; explicit `release_focus()` after modal dismiss.

### Tooling / CI

- **GUT flakes on tests using `await get_tree().process_frame`** inside `_ready`. Prefer `await get_tree().create_timer(0.0).timeout`.
- **`gdlint` vs GUT**: gdlint catches style issues GUT misses; both are pre-commit gates.
- **GUT does not recurse subdirs.** If `tests/unit/` or `tests/integration/` have subfolders, set `"include_subdirs": true` in `.gutconfig.json` or GUT only runs top-level files. Symptom: test count drops after a reorg.
- **GodotIQ `run(action="play")` timeouts**: expected with heavy loads; wait, `state_inspect`, then `run(stop)` before retry. Don't kill-and-respawn.

If you hit an edge case not on this list, append it here before closing your ticket.

---

## Active (in flight)

| Agent | Ticket | Branch | Files touched | Started | Notes |
|---|---|---|---|---|---|
| claude-main | SH-116 | sh-116-linux-release-channel | .github/workflows/release.yml | 2026-04-19 | Switch prod release to Linux preset + `linux` channel; preview stays web; waiting on Josh's Linux export preset commit to land on main |
| sh-118-agent | SH-118 | sh-118-pin-supply-chain | .github/workflows/{test,publish,release}.yml | 2026-04-19 | Pin Godot + export templates + butler to SHA256; folds in SH-119 |
| sh-126-agent | SH-126 | sh-126-pip-audit | lefthook.yml, requirements-dev.txt | 2026-04-19 | Add pip-audit pre-commit hook, fires only when requirements-dev.txt staged |
| sh-121-agent | SH-121 | sh-121-dependabot-config | .github/dependabot.yml | 2026-04-19 | Dependabot weekly for github-actions + pip, PRs assigned to J-Melon |
| agent-a812569c | SH-135 | sh-135-release-ci-speed-pass | .github/workflows/release.yml | 2026-04-19 | CI speed pass on release.yml (concurrency, job-level permissions, `.godot/` import cache, timeout-minutes); SH-131 follow-up punted from release.yml due to SH-132 contention; overlaps SH-116 on same file — whichever lands second merges main in |
| claude-ci | SH-131 | sh-131-ci-speed | .github/workflows/{test,lint,publish,sync-wiki}.yml | 2026-04-19 | CI speed pass: concurrency, permissions, import cache; skipping release.yml to avoid collision with SH-116 |
| sh-117-agent | SH-117 | sh-117-security-md | SECURITY.md, README.md | 2026-04-19 | Add SECURITY.md at repo root (scope, reporting, timeline, safe harbour); link from README |
| agent-a5879155 | SH-146 | sh-146-slsa-provenance | .github/workflows/release.yml | 2026-04-19 | Add SLSA build provenance attestation for Linux/Windows/macOS artifacts; overlaps SH-116/SH-135 on same file — last to land merges main in |
| sh-149-agent | SH-149 | sh-149-merge-queue | .github/workflows/{auto-update-prs,lint,test}.yml, ai/PARALLEL.md, designs/process/labels.md | 2026-04-19 | Delete PR sweep workflow, add `merge_group:` trigger to lint/test, doc the merge queue flow |
| agent-a92fe95a | SH-147 | sh-147-release-drafter | .github/release-drafter.yml, .github/workflows/release-drafter.yml | 2026-04-19 | Add release-drafter to auto-draft release notes (config + workflow, SHA-pinned @v7.2.0, Conventional Commit categories); Josh still picks tag + body at publish |
| agent-a2c0e37b | SH-145 | sh-145-pr-template | .github/pull_request_template.md | 2026-04-19 | Minimal PR template: ticket ID, what, why, risks; no test plan |
| agent-ae2182d2 | SH-134 | sh-134-headless-daily-cycle | .github/workflows/daily-cycle.yml | 2026-04-19 | Weekday 05:17 UTC cron: pick eligible Linear-cycle ticket, dispatch headless Claude per ai/PARALLEL.md; stops at PR handoff, no merge, no runtime; fails closed on missing secrets / halt file |

## Done (recent)

| Agent | Ticket | PR | Merged | Notes |
|---|---|---|---|---|
| sh-52-agent | SH-52 | (commit 05e0f47, branch sh-52-organize-unit-tests, not pushed) | pending | Organized 35 unit tests into 9 domain subfolders; enabled gut include_subdirs; 345 tests pass |

## Blocked / escalated

| Ticket | Agent | Reason | Raised | Resolution |
|---|---|---|---|---|
| _(none)_ | | | | |

---

## Activity log

Newest at top. One line per event.

```
[SH-134] agent-ae2182d2: claimed, branch sh-134-headless-daily-cycle; added .github/workflows/daily-cycle.yml (cron 17 5 * * 1-5 + dispatch, Linear GraphQL eligibility filter, fail-closed on missing secrets / halt file, 60min job + 40-turn Claude caps, ntfy telemetry); PR #255 open; ci-and-workflows specialist dispatched
[SH-146] agent-a5879155: claimed, branch sh-146-slsa-provenance; add attest-build-provenance step + id-token/attestations perms on deploy-production; overlaps SH-116/SH-135 same file
[SH-118] sh-118-agent: claimed; pinning Godot 4.6.2 binary+templates and butler 15.26.1 to SHA256 across test/publish/release workflows (also closes SH-119)
[SH-147] agent-a92fe95a: claimed, branch sh-147-release-drafter; added .github/release-drafter.yml (Conventional-Commit categories, autolabeler, narrative template) + .github/workflows/release-drafter.yml (SHA-pinned release-drafter@v7.2.0, contents: write + pull-requests: read)
[SH-145] agent-a2c0e37b: claimed, branch sh-145-pr-template; added .github/pull_request_template.md (minimal: ticket, what, why, risks)
[SH-149] sh-149-agent: claimed, branch sh-149-merge-queue; deleted auto-update-prs.yml, added `merge_group:` trigger to lint+test, updated PARALLEL.md + labels.md for merge-queue flow
[SH-126] sh-126-agent: claimed, added pip-audit pre-commit hook gated on requirements-dev.txt glob; lefthook run pre-commit green, clean audit
[SH-121] sh-121-agent: claimed, added .github/dependabot.yml for github-actions + pip, weekly, assignee J-Melon
[SH-135] agent-a812569c: claimed; CI speed pass on release.yml (concurrency, permissions, .godot/ cache, timeout-minutes); overlaps SH-116 same file, no behaviour change
[SH-117] sh-117-agent: claimed, branch sh-117-security-md; wrote SECURITY.md + README Security link; cycle set to Bobo
[SH-131] claude-ci: claimed, branch sh-131-ci-speed; scope = test/lint/publish/sync-wiki; release.yml skipped (SH-116 active)
[SH-52] sh-52-agent: done, commit 05e0f47, 345/345 tests pass, lefthook green, not pushed
[init] scratchpad created, ready for claims
```
