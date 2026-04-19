# Parallel Processing Coordination — Volley!

Live scratchpad for parallel agent work on individual Linear tickets. One agent per ticket. Read this before starting; write a status line when you commit or block.

---

## How to use this doc

1. **Claim a ticket** — branch first (`git checkout -b sh-XX-...`), then add a row to the Active table with agent name, ticket ID, branch, and start timestamp. Commit the claim on the branch so it ships with the PR, not on main.
2. **Log progress** — append one line per meaningful step to the Activity Log at the bottom. Keep it terse: `[SH-XX] <agent> — <what happened>`.
3. **Finish** — move the row from Active to Done, note the commit SHA and PR number. After `gh pr create`, dispatch a code-reviewer sub-agent against the PR, apply every suggested fix as commits on the PR branch, push, then report. Don't wait for human approval of the auto-fixes — Josh reviews after.
4. **Block or spin** — if you loop on the same issue twice, escalate to Josh immediately (see Escalation). Do not try a third variant silently.

---

## Ground rules

- **One ticket, one agent, one branch.** Never two agents in the same `.gd`/`.tscn` file at once. Check the Active table's "Files touched" column before starting.
- **Rebase on main before opening PR.** Josh merges, you don't (per feedback rule).
- **Run `ggut` after every code change.** Iterate until green. Do not invoke lefthook manually; the pre-commit hook fires automatically on `git commit` against staged files. If the commit fails, fix and re-commit.
- **Godot tool discipline** — prefer GodotIQ MCP tools over raw file ops; never delete-and-rebuild scenes; `node_ops` + `save_scene` for `.tscn`.
- **Git aliases and helpers** — prefer `gcb` (checkout -b), `gst`, `gaa`, `gpsup` (push -u origin HEAD). For commits use the conventional-commit functions: `gcf "msg"` (feat), `gcx` (fix), `gcd` (docs), `gcr` (refactor), `gct` (test), `gch` (chore). All auto-signoff. Raw `git commit -s` only when you need a multi-line body.
- **Verify, don't assume.** Every change needs evidence: tool output or tests, not "looks correct".

---

## Escalation to Josh (early, not late)

Escalate the **first** time you hit any of these — circular failure modes are cheap to flag early and expensive to hide:

- **Loop detected** — tried two genuinely different strategies on the same failure. Stop. Do not try a third. Post to Activity Log with `ESCALATE:` prefix and include the failing evidence from both attempts.
- **Scope ambiguity** — the ticket AC is met but you're unsure if the spirit is satisfied, or the ticket touches a system you can't understand from design docs alone.
- **Cross-ticket collision** — your change forces edits in a file another active stream owns.
- **Design gap** — code says one thing, design doc says another, and the ticket doesn't pick a side.
- **External dependency shift** — Godot engine bug, addon regression, API change mid-task.

Escalation format in Activity Log:

```
ESCALATE [SH-XX] <agent> — <one-line summary>
  Tried: <strategy 1> → <evidence>
  Tried: <strategy 2> → <evidence>
  Question: <what you need Josh to decide>
```

---

## Godot edge cases to watch for

Compatibility traps that have bitten this project or are documented in Godot 4. Check against these before declaring a ticket done:

### Scene / node

- **`@onready` on renamed children silently breaks** — use `@export` for node refs (project rule).
- **Scene root path in `node_ops`** — paths are relative to scene root (`"Sun"` not `"Main/Sun"`).
- **`build_scene` ≤256 nodes per call** — split by parent if you exceed.
- **Delete-and-rebuild is banned** — surgical `node_ops` edits only, even for "just a few tiles".
- **`ClassName.new()` on freshly-written scripts** — class cache is async; use `load("res://path.gd").new()` for scripts touched this session.
- **Tool scripts** — `@tool` scripts run in the editor; `Engine.is_editor_hint()` guards are mandatory for any side-effectful `_ready()`.

### Signals / lifecycle

- **Signal orphans after refactor** — run `signal_map(find="orphans")` as part of QA gate; don't skip.
- **`tree_exiting` vs `tree_exited`** — `tree_exiting` fires before removal (node still valid); `tree_exited` fires after (don't touch the node). Getting this wrong causes freed-instance access.
- **Autoload order matters** — `project.godot` autoloads init top-to-bottom. `SaveManager`, `ItemManager`, `ProgressionManager`, `ConfigHotReload` — don't reorder without checking cross-deps.
- **`call_deferred` vs `set_deferred`** — physics/signal callbacks mutating tree state need `call_deferred`, not direct mutation, or you get "parent is busy" errors.

### Physics / CharacterBody / area

- **`move_and_slide` on `CharacterBody2D/3D` mutates `velocity` in place** — read after the call, not before.
- **`Area` signals fire once per overlap pair** — re-entering the same area doesn't re-fire unless monitoring toggled.
- **Layer vs mask asymmetry** — A detects B only if A's mask includes B's layer; not vice versa. Always check both sides.

### Resources / saves

- **`.tres` binary vs text** — text is required for version control diffs; check the resource save format flag.
- **No save backwards-compat shims** (project rule) — change the code, not the loader.
- **Resource UIDs** — `res://...` and `uid://...` can diverge after file moves; prefer UIDs for stable refs.

### Input / UI

- **`_input` vs `_unhandled_input`** — UI elements consume input first; gameplay input goes in `_unhandled_input` or it fires during menus.
- **`Control.mouse_filter = STOP` blocks children too** — set PASS on parents of clickable children.
- **Focus stealing** — buttons auto-grab focus on hover; explicit `release_focus()` after modal dismiss.

### Tooling / CI

- **`ggut` flakes on tests using `await get_tree().process_frame`** inside `_ready`. Prefer `await get_tree().create_timer(0.0).timeout`.
- **`gdlint` vs `ggut`** — gdlint catches style issues ggut misses; both are pre-commit gates.
- **`ggut` does not recurse subdirs.** If `tests/unit/` or `tests/integration/` have subfolders, set `"include_subdirs": true` in `.gutconfig.json` or gut only runs top-level files. Symptom: test count drops after a reorg.
- **GodotIQ `run(action="play")` timeouts** — expected with heavy loads; wait, `state_inspect`, then `run(stop)` before retry. Don't kill-and-respawn.

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
[SH-52] sh-52-agent — done, commit 05e0f47, 345/345 tests pass, lefthook green, not pushed
[init] scratchpad created — ready for claims
```
