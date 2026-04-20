# Godot edge cases

Compatibility traps that have bitten this project or are documented in Godot 4. Check against these before declaring a ticket done. Agents consult this at QA time; it is not required reading at ticket start.

## Scene / node

- **`@onready` on renamed children silently breaks**: use `@export` for node refs (project rule).
- **Scene root path in `node_ops`**: paths are relative to scene root (`"Sun"` not `"Main/Sun"`).
- **`build_scene` ≤256 nodes per call**: split by parent if you exceed.
- **Delete-and-rebuild is banned**: surgical `node_ops` edits only, even for "just a few tiles".
- **`ClassName.new()` on freshly-written scripts**: class cache is async; use `load("res://path.gd").new()` for scripts touched this session.
- **Tool scripts**: `@tool` scripts run in the editor; `Engine.is_editor_hint()` guards are mandatory for any side-effectful `_ready()`.

## Signals / lifecycle

- **Signal orphans after refactor**: run `signal_map(find="orphans")` as part of QA gate; don't skip.
- **`tree_exiting` vs `tree_exited`**: `tree_exiting` fires before removal (node still valid); `tree_exited` fires after (don't touch the node). Getting this wrong causes freed-instance access.
- **Autoload order matters**: `project.godot` autoloads init top-to-bottom. Current order is `SaveManager`, `ItemManager`, `ProgressionManager`, `ConfigHotReload`. Don't reorder without checking cross-deps.
- **`call_deferred` vs `set_deferred`**: physics/signal callbacks mutating tree state need `call_deferred`, not direct mutation, or you get "parent is busy" errors.

## Physics / CharacterBody / area

- **`move_and_slide` on `CharacterBody2D/3D` mutates `velocity` in place**: read after the call, not before.
- **`Area` signals fire once per overlap pair**: re-entering the same area doesn't re-fire unless monitoring toggled.
- **Layer vs mask asymmetry**: A detects B only if A's mask includes B's layer, not vice versa. Always check both sides.

## Resources / saves

- **`.tres` binary vs text**: text is required for version control diffs; check the resource save format flag.
- **No save backwards-compat shims** (project rule): change the code, not the loader.
- **Resource UIDs**: `res://...` and `uid://...` can diverge after file moves; prefer UIDs for stable refs.

## Input / UI

- **`_input` vs `_unhandled_input`**: UI elements consume input first; gameplay input goes in `_unhandled_input` or it fires during menus.
- **`Control.mouse_filter = STOP` blocks children too**: set PASS on parents of clickable children.
- **Focus stealing**: buttons auto-grab focus on hover; explicit `release_focus()` after modal dismiss.

## Tooling / CI

- **GUT flakes on tests using `await get_tree().process_frame`** inside `_ready`. Prefer `await get_tree().create_timer(0.0).timeout`.
- **`gdlint` vs GUT**: gdlint catches style issues GUT misses; both are pre-commit gates.
- **GUT does not recurse subdirs.** If `tests/unit/` or `tests/integration/` have subfolders, set `"include_subdirs": true` in `.gutconfig.json` or GUT only runs top-level files. Symptom: test count drops after a reorg.
- **GodotIQ `run(action="play")` timeouts**: expected with heavy loads; wait, `state_inspect`, then `run(stop)` before retry. Don't kill-and-respawn.

If you hit an edge case not on this list, append it here before closing your ticket.
