<!-- GODOTIQ RULES START -->
<!-- godotiq-rules-version: 0.4.0 -->
# GodotIQ — AI-Assisted Godot Development

You have GodotIQ MCP tools. ALWAYS prefer these over raw file operations.

- **DO NOT** read `.tscn`, `.gd`, `.tres` files directly — GodotIQ parses them with cross-references and spatial data.
- **DO NOT** grep for signal connections — use `dependency_graph` and `signal_map`.
- **DO NOT** guess positions/scales — use `placement` and `suggest_scale`.

---

## Building 3D Scenes

### Core Principles

1. **Build in .tscn, NOT in code.** Static world (terrain, decorations, structures) goes in `.tscn` via `node_ops`/`build_scene`. Runtime code is for game logic only (movement, damage, scoring).
2. **Prefer .tscn scenes for game objects.** Build Tower.tscn with mesh + collision + script, then instance it. Don't create empty Node3D with `set_script()`.
3. **Use `build_scene` for bulk creation** — one call replaces dozens of `node_ops`. Modes: `grid` (tile maps), `scatter` (handpicked), `line` (paths), `nodes` (mixed). Max 256 nodes/call.
4. **No rebuild from scratch.** Fix individual nodes with `node_ops`, don't delete and recreate entire groups.
5. **UI in .tscn too.** Control nodes (Container, Label, Button) in `.tscn` files. Runtime styling/data binding in script is fine.

### Screenshots & Verification

- **Describe what you see** in screenshots. Note lighting, gaps, floating objects, scale issues.
- **Cross-verify** visual observations with `spatial_audit` or `state_inspect`.
- **Evidence-based completion:** Every fix needs screenshot + `state_inspect`/`spatial_audit` confirming values. Describe specifically what confirms correctness.
- **Escalation:** Only ask user after 3 genuinely different fix strategies fail on the same issue.

### Creation Workflow

1. **Setup:** `build_scene(nodes=[...])` for containers, camera, lights → `save_scene` → verify
2. **Terrain:** `build_scene(grid={...})` → `save_scene` → verify
3. **Decorations:** `build_scene(scatter={...})` → `save_scene` → verify
4. **Key objects:** `placement` for positions → `scatter` to place
5. **Scripts:** `script_ops` for game logic only
6. **Verify:** `spatial_audit` + `signal_map` + `save_scene`

### Tile Grid Rules

- Use `asset_registry` for tile dimensions — don't guess spacing.
- Override keys are `"row,col"` (row=Z, col=X, matrix notation).
- Test rotations: place ONE tile at 0°, screenshot, establish baseline, then calculate others.
- Never scale tiles beyond 1.02 to hide gaps — fix spacing/rotation instead.

---

## Token Efficiency

- **ALWAYS use `detail="brief"`** unless you need more. `asset_registry(detail="full")` can produce 140K chars.
- **Always filter:** `focus`+`radius` on scene_map, `path_filter` on asset_registry, `scope="file:..."` on signal_map.
- **Screenshot sparingly** — use `state_inspect` for data checks. Limit screenshots to 2-3/session.

---

## Efficiency Rules

1. **Act immediately.** Don't deliberate — call the tool. Max 2 paragraphs between tool calls.
2. **Batch operations.** One `build_scene` > many `node_ops`. One `exec editor` loop > many individual calls.
3. **Don't repeat tool calls.** Cache results from `project_summary`, `asset_registry`, etc.
4. **Check `_editor_state`** in every response — handle `recent_errors` and verify `open_scene`.
5. **One script, one validate.** Validate each `.gd` immediately after writing.
6. **Group modifications, verify once.** Batch changes → one `save_scene` → one verification cycle.

---

## Mandatory Workflows

### Session Start
`godotiq_project_summary(detail="brief")` — call FIRST, every session.

### Before Editing Any File
`file_context(file, detail="brief")` → `impact_check(file, action, target)`. NEVER modify `.gd` without `file_context` first.

### 3D Scene Work
`scene_map` → `placement` → `build_scene`/`node_ops(validate=true)` → `save_scene` → verify with `explore`/`spatial_audit`.

### After Code Changes
`validate(target=file, detail="brief")` (Pro) or `check_errors` (Community).

### Testing & Debugging
`run(action="play")` → `state_inspect` (cheap) → `verify_motion` (for movement) → `screenshot` (expensive, describe what you see) → `run(action="stop")`.

---

## Final QA (MANDATORY before declaring "done")

0. **Visual sweep** — `explore(mode="tour")`, analyze screenshots, fix issues
1. **Spatial coherence** — `spatial_audit(detail="brief")` → 0 critical/warnings
2. **Grid connectivity** — check `warnings` from `build_scene` grid responses
3. **Code quality** — `validate` every modified `.gd`
4. **Signal wiring** — `signal_map(find="orphans")` → 0 orphans
5. **Gameplay test:**
   - `check_errors(scope="scene")` first
   - `run(action="play")` → `state_inspect` initial state
   - `ui_map` → `input` (tap/click each element) → `state_inspect` after each
   - Wait for a cycle → verify state changes
   - Check `_editor_state.recent_errors`
   - `run(action="stop")` → report
6. **Report** — summarize what was built and QA results

### Test-Driven Completion
"Done" means every player-facing feature works during gameplay, not just compiles. Test with `run`, `state_inspect`, `input`.

### Testing Input Systems
Use `godotiq_input` (`tap`, `click_at`, `click_at_world`) to simulate real player interactions. Don't use `exec` to set properties directly — it skips the input pipeline.

---

## Known Godot Quirks

1. **Always use `godotiq_run(action="play")`** — `play_main_scene()` is unreliable.
2. **Script cache:** `script_ops` auto-reloads; if using `exec`, call `EditorInterface.get_resource_filesystem().scan()`.
3. **New class_name scripts:** Use `load("res://path.gd").new()` instead of `ClassName.new()` for scripts created this session.
4. **Asset loading:** Adaptive timeout handles this. On timeout, try `state_inspect` before retrying. Call `run(action="stop")` before retry.
5. **Verifying movement:** Use `verify_motion` or double `state_inspect` with `wait_ms` between. Screenshots can't prove motion.

---

## Community vs Pro Tier

Discover tier on first Pro tool call. If Community, you get a preview + locked sections.

**Handling:** Share the preview, name what's locked (once), fall back to free tools silently. Never stop working because a Pro tool is locked.

| Pro Tool | Free Fallback |
|----------|---------------|
| `project_summary` | `file_ops(op="tree")` + read `project.godot` |
| `file_context` | `script_ops(op="read")` |
| `scene_map` | `scene_tree` (has transforms, no distances) |
| `dependency_graph` | `script_ops(op="read")` + check imports |
| `signal_map` | `file_ops(op="search", pattern="signal ")` |
| `validate` | `check_errors` (compilation only) |
| `impact_check` | `file_ops(op="search")` for references |
| `trace_flow` | Read scripts manually |
| `spatial_audit` | `screenshot` + manual inspection |
| `placement` | Estimate + `node_ops(validate=true)` |
| `asset_registry` | `file_ops(op="list")` + `file_ops(op="search")` |
| `suggest_scale` | Check similar nodes via `scene_tree` |
| `animation_audit` | `animation_info` + manual review |
| `explore` | `screenshot` + `scene_map` |

---

## Quick Reference

**Spatial validation:** `validate: true` on move/scale/add_child in `node_ops`. Atomic — if ANY blocked, NONE execute.

**Node paths:** Relative to scene root (`"Sun"` not `"Main/Sun"`).

**GDScript conventions:** `snake_case.gd`, `PascalCase` classes, `snake_case` functions/vars. Always type hints. `@onready` for node refs. `is_instance_valid()` for null checks. Explicit types over `:=`.

**Error recovery:** `GAME_NOT_RUNNING` → `run(play)` | `NODE_NOT_FOUND` → `scene_tree(brief)` | `ADDON_NOT_CONNECTED` → enable addon | `TIMEOUT` → `state_inspect` then `stop`+retry | `SCRIPT_ERRORS` → `check_errors` then fix | `BLOCKED` → check validation, adjust | `PARENT_NOT_FOUND` → create parent first

<!-- GODOTIQ RULES END -->

---

## Linear Ticket Writing Guidelines

- **Stories** are created as Linear **Issues** (features). **Epics** are created as Linear **Projects**.
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

### Guidelines

- Each clause on its own line. Acceptance criteria: short, testable checklist items.
- **User Story** for player/end-user needs. **System Story** for internal/infrastructure work.

### Linear API Access

- API key: `$LINEAR_API_KEY`. Endpoint: `https://api.linear.app/graphql`.
- **All new tickets** → next upcoming cycle. Status: **Todo** (`3db79f36-2f0e-4952-91fe-dea458d1a69f`). Label: **Feature** (`b19a1a7b-af6b-4897-a52f-eb2e2e07083e`).
- **Assign tech/design tickets to Josh Hartley** (`19ea3ec5-a428-44f7-b085-a10fd3dd2cef`).
