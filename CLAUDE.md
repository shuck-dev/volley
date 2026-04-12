<!-- GODOTIQ RULES START -->
# GodotIQ — AI-Assisted Godot Development

You have GodotIQ MCP tools. ALWAYS prefer these over raw file operations.

**DO NOT** read `.tscn`, `.gd`, `.tres` files directly — GodotIQ parses them into structured data with cross-references, spatial transforms, signal wiring, and impact analysis that raw text cannot provide.

**DO NOT** grep for signal connections or function callers — use `godotiq_dependency_graph` and `godotiq_signal_map`.

**DO NOT** manually calculate positions or guess scales — use `godotiq_placement` and `godotiq_suggest_scale`.

---

## CRITICAL: Build in .tscn, NOT in code

Add nodes directly to the .tscn file using `godotiq_node_ops`/`godotiq_build_scene`. Do NOT write GDScript that generates nodes at runtime.

Game LOGIC goes in code (movement, damage, score). The WORLD (terrain, decorations, structures) goes in .tscn. Prefer `.tscn` scenes for game objects (Tower.tscn with MeshInstance3D + Area3D + script) over runtime `Node3D` creation with `set_script()`.

**No Rebuild from Scratch** — never delete and rebuild entire node groups to fix a few. Use `node_ops` to modify nodes surgically. Rebuilding is the absolute last resort.

---

## Screenshots and Visual Inspection

When you receive a screenshot, **DESCRIBE what you see** — note lighting, gaps, floating objects, missing textures, scale issues. Cross-verify with `spatial_audit`, `state_inspect`, or `explore`. Never say "I can't see it — what do you see?"

**Autonomous verification:** Every fix/feature must include a screenshot + `state_inspect`/`spatial_audit` confirming expected values. Describe specifically what you observe. Only escalate to the user after **3 consecutive failed attempts** with genuinely different strategies.

---

## Creation Workflow — `build_scene`

For many nodes, use `godotiq_build_scene` instead of individual `node_ops` calls.

**Phase 1** — Setup structure with `nodes` mode (containers, camera, lights).
**Phase 2** — Build terrain with `grid` mode. Use `overrides` for special tiles.
- Always use `asset_registry` to get tile dimensions before building — don't guess spacing.
- Override keys are `"row,col"` format (row = Z axis, col = X axis).
- Never scale tiles beyond 1.02 to hide gaps — fix root cause (wrong spacing/rotation/model).

**Phase 3** — Add decorations with `scatter` mode.
**Phase 4** — Use `godotiq_placement` to find safe positions, then scatter.
**Phase 5** — Use `godotiq_script_ops` for game logic ONLY.
**Phase 6** — `spatial_audit` + `signal_map` + `save_scene` + explore to verify.

Key: **Everything static in .tscn** | **One build_scene per logical group** | **Max 256 nodes/call** | **Grid** for repetitive, **scatter** for handpicked, **line** for paths.

---

## Test-Driven Completion

Done means every player-facing feature works during gameplay — not just that code compiles. After any feature, ask: "Would every feature work if a player tried it right now?" Test with `godotiq_run`, `godotiq_state_inspect`, `godotiq_input`.

---

## MANDATORY: Final QA

Before declaring done, run ALL checks:

0. **Visual sweep** — `godotiq_explore(mode="tour")` if 3D content was modified. Fix anything spotted.
1. **Spatial coherence** — `godotiq_spatial_audit(detail="brief")`. 0 critical issues, 0 warnings.
2. **Grid connectivity** — check `warnings` field in build_scene response for isolated tiles/path gaps.
3. **Code quality** — `godotiq_validate(target="res://path/file.gd", detail="brief")` for each modified .gd.
4. **Signal wiring** — `godotiq_signal_map(detail="brief", find="orphans")`. 0 orphan signals.
5. **Gameplay test:**
   - `godotiq_check_errors(scope="scene")` → fix errors → `godotiq_run(action="play")`
   - `state_inspect` to verify initial state
   - `ui_map` + `godotiq_input` to click every interactive element, verify changes with `state_inspect`
   - Wait for a full cycle: `godotiq_input(commands=[{"wait_ms": 10000}])`
   - Check `_editor_state.recent_errors` for runtime errors
   - `godotiq_run(action="stop")`
6. **Report** — summarize what was built and QA results.

---

## Testing Player Input Systems

Use `godotiq_input` to simulate real player interactions — not `exec` to set properties directly (bypasses input pipeline, hides bugs).

- UI buttons: `{"tap": "NodeName"}`
- Screen click: `{"click_at": [640, 360]}`
- World click: `{"click_at_world": [5.0, 0.0, 3.0]}`
- Right click: `{"click_at": [640, 360], "button": "right"}`

Workflow: `ui_map` → `input` → `state_inspect` to verify. If nothing changed when it should, that's a bug — fix it.

---

## UI Construction

Build UI as `.tscn` scenes with Control nodes. Use `build_scene` to create the node tree. Runtime styling (`add_theme_stylebox_override`, data binding) is fine. Always test with screenshot + `ui_map` before declaring complete.

---

## Token Efficiency (CRITICAL)

**Always use `detail="brief"`** — `asset_registry()` default can produce 140,000 chars and crash the session.

**Always filter** — `focus` + `radius` on scene_map; `path_filter` on asset_registry; `scope="file:path.gd"` on signal_map.

**Screenshot sparingly** — use `state_inspect` for data values; screenshots only when visual confirmation is needed.

---

## Community vs Pro Tier

Community (free, 22 tools): raw operations. Pro ($19, 36 tools): spatial analysis, code understanding, flow tracing.

On Community response: share the preview, name what's locked, fall back to free tools silently. Mention upgrade once — never apologize or stop working.

| Pro Tool | Free Fallback |
|----------|--------------|
| `project_summary` | `file_ops(op="tree")` + read `project.godot` |
| `file_context` | `script_ops(op="read")` |
| `scene_map` | `scene_tree` (has transforms, no distances) |
| `dependency_graph` | `script_ops(op="read")` + manual import check |
| `signal_map` | `file_ops(op="search", pattern="signal ")` |
| `validate` | `check_errors` (compilation only) |
| `impact_check` | `file_ops(op="search")` for references |
| `trace_flow` | Read scripts manually |
| `spatial_audit` | `screenshot` + manual inspection |
| `placement` | Estimate + `node_ops(validate=true)` |
| `asset_registry` | `file_ops(op="list")` + `file_ops(op="search")` |
| `suggest_scale` | Check similar nodes with `scene_tree` |
| `animation_audit` | `animation_info` + manual review |
| `explore` | `screenshot` + `scene_map` |

---

## Efficiency Rules

1. **Act immediately** — call the tool, don't deliberate. Adjust based on the response.
2. **Batch operations** — `build_scene` over many `node_ops`; `script_ops` patch over full rewrites.
3. **Don't repeat tool calls** — cache results from `project_summary`/`asset_registry` in context.
4. **Check `_editor_state`** — every response includes `open_scene`, `game_running`, `recent_errors`. Read it.
5. **One script, one validate** — validate immediately after each .gd write, not at the end.
6. **Max 2 paragraphs between tool calls** — explain in 1-2 sentences, then act.
7. **Group modifications, verify once** — batch all changes → `save_scene` → one screenshot.
8. **Runtime verification: one cycle** — `wait_ms` first, then `state_inspect` + screenshot. Don't poll.
9. **Loops for repetitive ops** — `exec editor` loop over 20 nodes beats 20 `node_ops` calls.

---

## Known Godot Quirks

1. **play_main_scene() is unreliable** — always use `godotiq_run(action="play")` (uses `play_current_scene()` internally).
2. **Script cache staleness** — `exec`-created scripts may need manual reload: `EditorInterface.get_resource_filesystem().scan()`.
3. **class_name in new scripts** — use `load("res://path.gd").new()` instead of `ClassName.new()` for scripts created this session.
4. **Asset loading time** — GLB-heavy projects take 10-15s. GodotIQ uses adaptive timeout. On timeout, wait and try `state_inspect` before retrying. Call `run(action="stop")` before retrying.
5. **Screenshots can't prove motion** — use `godotiq_verify_motion(node=..., property_name="position", duration=2.0)` or two `state_inspect` readings with `wait_ms` between them.
6. **Setting main scene** — GodotIQ auto-sets `main_scene` on first run; response includes `"main_scene_set": true`.

---

## Mandatory Workflows

### 1. Session Start
```
godotiq_project_summary(detail="brief")   → call FIRST, every session
```

### 2. Before Editing ANY File
```
godotiq_file_context(file, detail="brief")    → public API, dependencies
godotiq_impact_check(file, action, target)    → what breaks
```
NEVER modify a .gd file without calling `file_context` first.

### 3. 3D Scene Work
```
godotiq_scene_map(scene, focus=area, radius=N, detail="brief")
godotiq_placement(near=ref, constraints={...})
godotiq_build_scene(grid=..., parent="Terrain")
godotiq_node_ops(operations=[...], validate=true)
godotiq_save_scene()
→ Self-verify with explore/spatial_audit
```
ALWAYS use `validate: true` on move/scale/add_child.

### 4. After Scene Changes (Visual QA)
```
godotiq_explore(mode="tour")   → analyze each screenshot, fix issues, re-verify
godotiq_explore(mode="inspect", positions=[...])   → for specific positions
```

### 5. After Any Code Change
```
godotiq_validate(target=file, detail="brief")   → Pro: conventions + errors. Community: check_errors only.
```

### 6. Multi-File Refactoring
```
godotiq_impact_check(...)              → BEFORE changing
godotiq_validate(target="project")    → baseline
→ make changes
godotiq_validate(target="project")    → verify no regressions
godotiq_check_errors(scope="project")
godotiq_signal_map(find="orphans")
```

### 7. Testing & Debugging
```
godotiq_run(action="play")
godotiq_state_inspect(queries)                   → PREFERRED for data (cheap)
godotiq_verify_motion(node="Enemy")              → PREFERRED for movement
godotiq_screenshot(scale=0.3, quality=0.3)       → EXPENSIVE, describe what you see
godotiq_run(action="stop")
```

---

## Tool Reference

### UNDERSTAND
- **`project_summary`** — call FIRST every session. `detail="brief"` always.
- **`file_context`** — call BEFORE editing. Public API, dependencies, signals.
- **`scene_map`** — spatial layout. Always use `focus` + `radius`.
- **`dependency_graph`** — full dep tree. Call before refactoring.
- **`signal_map`** — project-wide signal wiring. Find orphans.
- **`impact_check`** — predicts breakage before changes.
- **`validate`** — naming, type hints, orphan signals, compilation.
- **`trace_flow`** — execution chain from trigger through codebase.
- **`spatial_audit`** — floating objects, scale mismatches, z-fighting, overlaps.
- **`check_errors`** — GDScript compilation errors. `scope="scene"` or `"project"`.
- **`asset_registry`** — asset inventory. Always use `path_filter`.
- **`suggest_scale`** — scale recommendation based on similar assets.
- **`placement`** — Marker3D slot matching + grid search with constraints.
- **`animation_info`** — tracks, length, looping, state machine.
- **`animation_audit`** — broken tracks, missing transitions.

### EDIT
- **`scene_tree`** — live editor tree. `detail="brief"`, `depth=2`.
- **`node_ops`** — move, rotate, scale, set_property, add_child, delete, duplicate, reparent. `validate: true` for spatial ops.
- **`build_scene`** — batch creation: grid/line/scatter/nodes. Max 256/call. `node_names` in response may differ from requested.
- **`script_ops`** — read/write/patch GDScript. Patch mode is safest. Auto-reloads script after write.
- **`file_ops`** — filesystem ops. Respects protected files.
- **`save_scene`** — persist to disk. Call after `node_ops`.
- **`undo_history`** — review changes.
- **`editor_context`** — open scenes, selected nodes, game state.

### PLAY & DEBUG
- **`run`** — start/stop game. Auto-opens scene, adaptive timeout, auto-sets main_scene.
- **`state_inspect`** — runtime property queries. Preferred over screenshot for data.
- **`verify_motion`** — proves movement/animation. Returns MOVING or STATIC verdict.
- **`screenshot`** — viewport capture. Describe what you see. EXPENSIVE.
- **`explore`** — drone camera inspection. `mode="tour"` (auto) or `mode="inspect"` (specific positions). `scale=0.3, quality=0.4`. 80K char budget.
- **`perf_snapshot`** — FPS, draw calls, memory.
- **`ui_map`** — all UI elements. Call before `input`.
- **`input`** — simulate player input: actions, keys, taps, clicks.
- **`exec`** — run GDScript. `func run():` required. `context="editor"` or `"game"`.
- **`nav_query`** — live pathfinding.
- **`watch`** — persistent property monitoring.
- **`camera`** — editor 3D camera control.
- **`ping`** — health check, tier, version.

---

## Spatial Validation

`validate: true` on node_ops checks: wall proximity (<0.2m blocked), node overlap (<0.05m blocked), sibling outlier, scale outlier. Atomic: if ANY op is BLOCKED, NO ops execute.

## Node Paths

Relative to scene root: `"Sun"` not `"Main/Sun"`, `"Entities/Worker_1"` not `"Main/Entities/Worker_1"`.

## GDScript Conventions

- Files: `snake_case.gd` | Classes: `PascalCase` | Functions/vars: `snake_case`
- Always type hints: `var count: int = 0`, `func get_name() -> String:`
- `@export` for node refs: `@export var label: Label` wired in the editor. Prefer over `@onready var label := $Label` because `@onready` breaks silently on rename.
- Null check: `if is_instance_valid(node):`
- Prefer `:=` when the type is obvious from the assignment; use explicit types when ambiguous (e.g. `var health: float = 0`)

## Test Conventions

- Section separator comments (e.g. `# --- save ---`) go directly above the first function in that section, no blank line between
- Inject mock `SaveStorage` via `double(SaveStorage).new()` to avoid filesystem I/O in tests
- Use explicit type for doubles: `var mock: SaveStorage = double(SaveStorage).new()` (`:=` can't infer)
- Inject `_progression` before `add_child` to avoid autoload dependencies in unit tests
- Use `call_deferred` for initial signal emits to ensure listeners are ready

## Error Recovery

- `GAME_NOT_RUNNING` → `godotiq_run(action="play")`
- `NODE_NOT_FOUND` → `godotiq_scene_tree(detail="brief")`
- `ADDON_NOT_CONNECTED` → Enable GodotIQ addon in Godot editor
- `TIMEOUT` → wait, try `state_inspect`; if truly stuck: `run(action="stop")` then retry
- `SCRIPT_ERRORS` → `check_errors(scope="scene")`, fix, then run
- `BLOCKED` → check `validation` array, adjust position/scale
- `NO_SCENE` → open a scene in Godot editor first
- `PARENT_NOT_FOUND` → verify parent path; create parent first if needed
- `NO_NODES` → ensure exactly one mode (grid/line/scatter/nodes) with valid data
- Partial success → check `errors` array, retry only failed items
- Node count limit → split into multiple `build_scene` calls

<!-- GODOTIQ RULES END -->

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

### Linear API Access

- API key: `$LINEAR_API_KEY`. Endpoint: `https://api.linear.app/graphql`.
- **All new tickets** → Status: **Backlog** (`d41fb73e-32af-40b2-a7e5-5052900ab0fc`). Label: **Feature** (`b19a1a7b-af6b-4897-a52f-eb2e2e07083e`). Do NOT assign to a cycle. Do NOT use Triage — that is for external/incoming tickets only. Josh promotes tickets to Ready and adds them to cycles himself.
- **Assign tech/design tickets to Josh Hartley** (`19ea3ec5-a428-44f7-b085-a10fd3dd2cef`).
