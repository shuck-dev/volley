<!-- GODOTIQ RULES START -->
<!-- godotiq-rules-version: 0.5.13 -->
# GodotIQ — Core Rules

You have GodotIQ MCP tools (`godotiq_*`). ALWAYS prefer them over raw file operations on Godot files.

- **DO NOT** read `.tscn`/`.gd`/`.tres` directly with `Read`/`cat` — `file_context`, `scene_map` and `script_ops` return structured data with cross-references, transforms and signal wiring that raw text cannot provide.
- **DO NOT** grep for signal connections or function callers — `dependency_graph` / `signal_map` trace the complete graph in one call.
- **DO NOT** hand-calculate positions or guess scales — `placement` / `suggest_scale` return validated suggestions.
- **DO NOT** build the world in code: terrain, structures and decorations belong in `.tscn` via `build_scene`/`node_ops`; only game logic belongs in scripts.
- **DO NOT** write `.tscn`/`.gd` behind a running editor with native file tools — GodotIQ's write tools detect the editor and route safely; raw writes risk stale-buffer overwrites and UID corruption.

## Mandatory Workflows

1. **Session start:** `project_summary(detail="brief")` FIRST — architecture, autoloads, counts in ~500 chars.
2. **Before editing any file:** `file_context(file, detail="brief")`; for signature/signal changes also `impact_check(file, action, target)`. NEVER modify a `.gd` without `file_context` first.
3. **3D scene work:** `scene_map(focus, radius, detail="brief")` → `placement` for positions → `build_scene` (batches: grid/line/scatter) or `node_ops(validate=true)` → `save_scene()` → self-verify with `explore`/`spatial_audit`.
4. **Visual QA after scene work:** `explore(mode="tour")` — describe each screenshot, fix issues, tour again; `explore(mode="inspect", positions=[...])` for close-ups.
5. **After every code change:** `validate(target=file, detail="brief")` for Pro convention checks, then `check_errors(scope=file)` for compilation/parser errors. One script, one validate/check cycle — never batch five scripts then debug.
6. **Multi-file refactor:** `impact_check` BEFORE changing; `validate(target="project")` baseline before/after; then `check_errors(scope="project")` and `signal_map(find="orphans")`.
7. **Testing/debugging:** `run(action="play")` → `verify_project_runs()` → `read_debug_console()` for errors → `state_inspect` for values (cheap, preferred) → `verify_motion` for movement → `screenshot(scale=0.25, quality=0.3)` only when visuals changed (expensive) → `run(action="stop")`.

## Token Efficiency

- Default to `detail="brief"`; full payloads can emit 50k–140k chars and crash the session.
- Always filter: `focus`+`radius` (scene_map), `path_filter` (asset_registry), `scope="file:..."` (signal_map).
- Prefer `state_inspect` (~200 chars) over `screenshot` (10k+) when you need data, not pixels; max 1 screenshot per verification point.
- Batch: one `build_scene` or one `exec` loop beats 20 single `node_ops`; group edits → one `save_scene` → one verification cycle.
- Act on tool responses immediately; every bridge response carries `_editor_state` (open_scene, game_running, recent_errors) — react to it.

## Error Recovery

| Error | Action |
|---|---|
| `GAME_NOT_RUNNING` | `run(action="play")` |
| `RUNTIME_NOT_ATTACHED` | game playing but runtime tools unavailable: `run(action="stop")` then `play` to retry the handshake; if persistent, check the addon is enabled |
| `NO_GAME_SESSION` | restart the game with `run` |
| `NODE_NOT_FOUND` | `scene_tree(detail="brief")` to find the correct name |
| `ADDON_NOT_CONNECTED` | enable the GodotIQ addon in the Godot editor |
| `BLOCKED_EDITOR_OPEN` | the editor is open: use bridge ops (`node_ops`/`script_ops`/`save_scene`) instead of direct disk writes |
| `TIMEOUT` | wait, check `state_inspect`; truly dead → `run(action="stop")`, retry |
| `SCRIPT_ERRORS` | `check_errors(scope="scene")`, fix the scripts, rerun |
| `BLOCKED` (node_ops) | read the `validation` array, adjust position/scale |
| `NO_SCENE` / `PARENT_NOT_FOUND` / `NO_NODES` (build_scene) | open a scene / fix or create the parent / pass exactly one mode with valid data |
| Partial success (build_scene) | check `errors`, retry only the failed items |

## Conventions

- GDScript: `snake_case.gd` files, `PascalCase` classes, type hints everywhere (`var hp: int = 0`, `-> void`), `@onready` for node refs, `is_instance_valid()` for null checks.
- `node_ops` paths are relative to the scene root: `"Entities/Worker_1"`, not `"Main/Entities/Worker_1"`.
- Scripts created this session: reference with `load()`, not `preload()`.

**Full reference:** `GODOTIQ_RULES.md` in the project root — read the relevant section before non-trivial work (3D building patterns, Godot quirks, verification recipes, spatial validation, per-tool reference).
<!-- GODOTIQ RULES END -->

<!-- GodotIQ rules — trimmed locally. Running `godotiq install-addon` will overwrite this file;
     remove the markers below if you want to re-inject fresh upstream rules. -->

# GodotIQ — AI-Assisted Godot Development

Before ticketed work where another agent may be active, read `.claude/skills/dispatch/SKILL.md` for the seven-step minion flow and check `gh pr list --state open --json files,headRefName,number` plus `mcp__linear__list_issues(state="Dispatched", cycle="active")` for what's already in flight.

Prefer GodotIQ MCP tools over raw file operations. Don't `Read`/`cat` `.tscn`/`.gd`/`.tres` (use `file_context`, `scene_map`, `scene_tree`). Don't grep for signals/callers (use `dependency_graph`, `signal_map`). Don't guess positions/scales (use `placement`, `suggest_scale`, `scene_map`).

## Scene construction

- Static world (terrain, decorations, static structures, UI containers) lives in `.tscn`, built via `build_scene`/`node_ops`. Runtime code is for game logic only, not scene construction.
- Prefer authored `.tscn` scenes for game objects (towers, enemies, projectiles, UI) over runtime `Node3D.new()` + `set_script()`. Exception: genuinely dynamic pools (bullets, particles).
- UI: build as `.tscn` with Control nodes. Runtime theme overrides and data binding are fine.
- Never delete-and-rebuild a group to fix a few items — surgical `node_ops` edits only.
- Paths in `node_ops` are relative to scene root (`"Sun"`, not `"Main/Sun"`).

### `build_scene` patterns

- `grid` for repetitive tiles, `scatter` for handpicked placements, `line` for paths, `nodes` for mixed containers/cameras/lights.
- Max 256 nodes per call. One `build_scene` = one undo.
- Override keys are `"row,col"` (row→Z axis, col→X axis). Row first.
- Get tile dimensions from `asset_registry` before choosing spacing. Never scale tiles >1.02 to close gaps — fix spacing/rotation/model instead.
- Test tile rotations by placing one at 0° first, noting default direction, then deriving others. Three wrong rotations → re-check the baseline.

### Spatial validation

Pass `validate: true` on move/scale/add_child. Atomic batch — any BLOCK aborts the whole batch. Checks: wall proximity (<0.2m blocks), node overlap (<0.05m blocks), sibling/scale outlier (warns).

## Verification and QA

Verify your own work; don't ask the user to check. Every change needs evidence: a screenshot + `state_inspect`/`spatial_audit` confirming expected values, plus a description of what you observe. "Looks correct" is not evidence.

**Escalate after 3 genuinely different strategies have failed on the same issue** (not 3 minor variations). Include failing evidence from all three when escalating.

When you see a screenshot, describe it and cross-verify with tools. Vision is fallible — name uncertainties in the final report.

### Final QA before "done"

Runs in order. If any step fails, fix before proceeding:

0. If 3D content changed: `explore(mode="tour")`, analyse each screenshot, fix issues.
1. `spatial_audit(detail="brief")` — 0 criticals, 0 warnings.
2. `build_scene` grid/path `warnings` field resolved (isolated tiles, gaps).
3. `validate(target=file, detail="brief")` on every new/modified `.gd`.
4. `signal_map(detail="brief", find="orphans")` — 0 orphans.
5. Gameplay test:
   - `check_errors(scope="scene")` first; fix before running.
   - `run(action="play")`, verify starting state with `state_inspect`.
   - `ui_map(detail="brief")` → exercise every interactive element with `input` (`tap`, `click_at`, `click_at_world`) → verify with `state_inspect`.
   - Wait a full cycle (`input(commands=[{"wait_ms": N}])`), verify loop progression.
   - Read `_editor_state.recent_errors` on every response.
   - `run(action="stop")` and summarise.
6. Report what was built + QA results.

"Done" means every player-facing feature works in real gameplay — not that it compiles.

### Testing player input

Simulate via `input` so the full pipeline exercises. `{"tap": "Name"}` for UI buttons, `{"click_at": [x,y]}` for viewport, `{"click_at_world": [x,y,z]}` for 3D, `"button": "left|right|middle"` for button. Exec-writing properties bypasses input handling and hides bugs — don't use it for testing.

### Verifying movement

Screenshots can't prove motion. Use `verify_motion(node, property_name, duration)` for `position`/`rotation`/`scale`/`modulate`. Or take two `state_inspect` readings around a `wait_ms` and diff.

## Efficiency

- Act, don't deliberate. Tool errors are cheap — try, read the response, adjust.
- Default every tool to `detail="brief"`. `asset_registry(detail="full")` can be 140K chars.
- Always filter: `focus`+`radius` on `scene_map`, `path_filter` on `asset_registry`, `scope="file:..."` on `signal_map`.
- Batch: one `build_scene` > 20 `node_ops`; one `script_ops` patch > full rewrite.
- Don't re-call `project_summary`/`asset_registry` in the same session — keep results in context.
- Check `_editor_state` (open scene, game running, recent errors) on every response. Avoids redundant `editor_context` calls.
- Validate each `.gd` immediately after writing it, not in bulk.
- Prefer `state_inspect` over `screenshot`. Screenshots cost thousands of tokens — cap at 2-3 per session.
- Group modifications, then one `save_scene`, then one verification.
- For repeated ops on many nodes (rotate 7 tiles, set one property on 20), loop in `exec editor` instead of separate calls.

## Mandatory workflows

**Session start:** `project_summary(detail="brief")`.

**Before editing any `.gd`:** `file_context(file, detail="brief")`; add `impact_check` for renames/removals/signature changes.

**3D scene work:** `scene_map(focus, radius, detail="brief")` → `placement` (if needed) → `build_scene`/`node_ops(validate=true)` → `save_scene` → `explore`/`spatial_audit`.

**After any code change:** `validate(target=file, detail="brief")`.

**Multi-file refactor:** `impact_check` first, baseline `validate(target="project")`, change, re-`validate`, `check_errors(scope="project")`, `signal_map(find="orphans")`.

**Testing/debug:** `run(play)` → `state_inspect`/`verify_motion` → `screenshot` only if visual needed → `run(stop)`.

## Known quirks

- `godotiq_run(action="play")` handles `play_main_scene` unreliability + asset-heavy load times (adaptive timeout) + auto-sets `main_scene`. On timeout: wait, check `state_inspect`, then `run(stop)` before retry.
- Scripts written via `script_ops` auto-reload. Scripts created via `exec` need `EditorInterface.get_resource_filesystem().scan()`.
- For scripts created or modified this session, use `load("res://path.gd").new()` rather than `ClassName.new()` — the class-name cache updates async.

## Background agents

If parallelising: after completion, read every file the agent touched, `check_errors(scope="project")`, `validate` each new/modified script, run the game and verify. Prefer sequential for overlapping files — concurrent writes silently overwrite.

## Tool reference (one-liners)

Understand: `project_summary` (first call), `file_context` (before editing), `scene_map` (before placing 3D), `dependency_graph` (before refactor), `signal_map` (wiring, orphans), `impact_check` (blast radius), `validate` (conventions + compile), `check_errors` (compile only), `trace_flow` (execution chain), `spatial_audit` (3D issues), `asset_registry` (inventory), `suggest_scale`, `placement`, `animation_info`, `animation_audit`.

Edit: `scene_tree` (live editor tree), `node_ops` (batch edit, `validate:true`), `build_scene` (grid/line/scatter/nodes), `script_ops` (read/write/patch), `file_ops`, `save_scene`, `undo_history`, `editor_context`.

Runtime: `run`, `state_inspect`, `verify_motion`, `screenshot`, `explore` (tour/inspect), `perf_snapshot`, `ui_map`, `input`, `exec` (`func run():` required, `context="editor|game"`), `nav_query`, `watch`, `camera`.

Utility: `ping` (version, tier, update).

## Error recovery

- `GAME_NOT_RUNNING` → `run(play)`.
- `NODE_NOT_FOUND` → `scene_tree(detail="brief")` to find the correct path.
- `ADDON_NOT_CONNECTED` → enable the GodotIQ addon in the editor.
- `TIMEOUT` → wait, `state_inspect`, then `run(stop)` before retry.
- `SCRIPT_ERRORS` → `check_errors(scope="scene")`, fix, retry.
- `BLOCKED` (node_ops) → check `validation`, adjust position/scale.
- `NO_SCENE`/`PARENT_NOT_FOUND`/`NO_NODES` (build_scene) → open a scene / create parent / pick exactly one mode.
- Partial success (build_scene) → retry only `errors` entries.
- `>256 nodes` → split into multiple `build_scene` calls grouped by parent.

---

## Linear Ticket Writing Guidelines

- **Stories** are Linear **Issues**. **Epics** are Linear **Projects**.
- Each ticket is either a **User Story** or a **System Story**.

### User Story Format

```
As a [role]
I want [capability]
So that [benefit]

**Acceptance Criteria:**
- [ ] ...
```

### System Story Format

```
[ACTION-VERB] [statement of what the system does]
So that [benefit or reason]

**Acceptance Criteria:**
- [ ] ...
```

### Bug Report Format

```
**Summary:** [One-line description of the bug]

**Steps to Reproduce:**
1.
2.
3.

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Environment:**
- Scene: [e.g. res://scenes/GameMain.tscn]
- Conditions: [e.g. "only when upgrade purchased", "after round 2"]

**Acceptance Criteria:**
- [ ] [Specific, testable condition that confirms the bug is fixed]
- [ ] No regression in related systems
```

### Guidelines

- Each clause on its own line. Acceptance criteria: short, testable checklist items.
- **User Story** for player/end-user needs. **System Story** for internal/infrastructure work.
- **Bug Report** for defects — use steps to reproduce and clear expected vs actual.
- **Issue titles ≤50 chars.** Push symptoms, qualifiers, file paths into the body.
- **Project names are Title Case, two words max per level.** "Security Hygiene", not "Security hygiene pass".

### Linear API Access

- API key: `$LINEAR_API_KEY`. Endpoint: `https://api.linear.app/graphql`.
- **All new tickets** → Status: **Vault** (`d41fb73e-32af-40b2-a7e5-5052900ab0fc`). Label: **Feature** (`b19a1a7b-af6b-4897-a52f-eb2e2e07083e`). Do NOT assign to a cycle. Do NOT use Triage; that is for external/incoming tickets only. Josh promotes tickets to Ready and adds them to cycles himself.
- **Never set an assignee.** Leave every ticket unassigned, in any state. Collaborators are joining the project; who picks up a ticket is theirs to decide, not something to impose by API.

