# Parallel Processing Coordination: Volley!

Live scratchpad for parallel agent work on individual Linear tickets. One agent per ticket. Read this before starting, and log progress in the Activity Log at the bottom (see "How to use this doc" for cadence).

---

## How to use this doc

1. **Claim a ticket.** Branch first (`git checkout -b sh-XX-...`), then add a row to the Active table with agent name, ticket ID, branch, and start timestamp. Commit the claim on the branch so it ships with the PR, not on main.
2. **Log progress.** Append one line per meaningful step to the Activity Log at the bottom. Keep it terse: `[SH-XX] <agent>: <what happened>`.
3. **Sync before opening, and sync again before any later push.** Before `gh pr create`, run `git fetch origin main && git merge origin/main` into your branch, resolve conflicts, re-run `ggut`, then push. After the PR exists, do the same check whenever you resume work, after a reviewer asks for changes, and before Josh is asked to merge: other PRs may have landed on main and made this branch stale. `git rev-list --count HEAD..origin/main` gives you the "behind by N" count; zero means you're up to date. This catches conflicts locally instead of surfacing them in the PR view for Josh to chase.
4. **Finish.** Move the row from Active to Done, note the commit SHA and PR number. After `gh pr create`, dispatch a code-reviewer sub-agent against the PR, apply every suggested fix as commits on the PR branch, push, then report. Don't wait for human approval of the auto-fixes; Josh reviews after.
5. **Block or spin.** If you loop on the same issue twice, escalate to Josh immediately (see Escalation). Do not try a third variant silently.

---

## Ground rules

- **One ticket, one agent, one branch.** Never two agents in the same `.gd`/`.tscn` file at once. Check the Active table's "Files touched" column before starting.
- **Never rebase; merge main in.** To update a branch with main, use `git merge main`, never `git rebase`. If a rebase is genuinely required (rare, e.g. cleaning history before first push), stop and ask Josh first. Josh merges PRs; agents don't.
- **Run `ggut` after every code change.** Iterate until green. Do not invoke lefthook manually; the pre-commit hook fires automatically on `git commit` against staged files. If the commit fails, fix and re-commit.
- **Godot tool discipline**: prefer GodotIQ MCP tools over raw file ops; never delete-and-rebuild scenes; `node_ops` + `save_scene` for `.tscn`.
- **Git aliases and helpers**: prefer `gcb` (checkout -b), `gst`, `gaa`, `gpsup` (push -u origin HEAD). For commits use the conventional-commit functions: `gcf "msg"` (feat), `gcx` (fix), `gcd` (docs), `gcr` (refactor), `gct` (test), `gch` (chore). All auto-signoff. These are oh-my-zsh functions and may not exist in other shells; fall back to raw `git` (with `-s` for sign-off) if unavailable. Raw `git commit -s` is also fine when you need a multi-line body.
- **Verify, don't assume.** Every change needs evidence: tool output or tests, not "looks correct".

---

## Godot session tiers

Three tiers of Godot access. Pick the lowest tier that answers your question. Higher tiers cost more isolation and, for Tier 2, need Josh's consent.

| Tier | What it covers | Parallelism | Needs an editor? |
|---|---|---|---|
| **0 — Static** | `ggut`, `validate`, `file_context`, `signal_map`, `impact_check`, edits to `.gd`, grep, read | High. N agents in parallel. | No. Headless forks. |
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

- **`ggut` flakes on tests using `await get_tree().process_frame`** inside `_ready`. Prefer `await get_tree().create_timer(0.0).timeout`.
- **`gdlint` vs `ggut`**: gdlint catches style issues ggut misses; both are pre-commit gates.
- **`ggut` does not recurse subdirs.** If `tests/unit/` or `tests/integration/` have subfolders, set `"include_subdirs": true` in `.gutconfig.json` or gut only runs top-level files. Symptom: test count drops after a reorg.
- **GodotIQ `run(action="play")` timeouts**: expected with heavy loads; wait, `state_inspect`, then `run(stop)` before retry. Don't kill-and-respawn.

If you hit an edge case not on this list, append it here before closing your ticket.

---

## Active (in flight)

| Agent | Ticket | Branch | Files touched | Started | Notes |
|---|---|---|---|---|---|
| _(none)_ | | | | | |

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
[SH-52] sh-52-agent: done, commit 05e0f47, 345/345 tests pass, lefthook green, not pushed
[init] scratchpad created, ready for claims
```
