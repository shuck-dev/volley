# Fixtures

An item with a physical prop on the court carries a `Fixture` resource. Stat-only items leave `fixture` null.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), World (`08-world.md`).

---

## Authoring

```gdscript
# ItemDefinition
@export var role: StringName       # ball, court, or equipment
@export var fixture: Fixture       # optional

class_name Fixture
extends Resource

@export var prop_scene: PackedScene
@export var dock_marker: StringName    # override; used by bot dock
```

Runtime state, signals, and system overrides live on the prop scene's root script. The `Fixture` is just "what to spawn."

---

## Where fixtures parent

By role:

- **`ball`** — ball fixtures are balls themselves; spawn under the arena's ball manager at the ball-spawn origin.
- **`court`** — court fixtures spawn at the next free marker under `Roles/Court` (see `08-roles.md`).
- **`equipment`** — equipment fixtures parent under the matching attachment node on `paddle.tscn` (`Handle`, `Head`, etc.).

`dock_marker` forces a named marker regardless of role resolution.

---

## FixtureManager

Lives on the court scene. Subscribes to `ItemManager.court_changed`; spawns and frees props to match.

```gdscript
class_name FixtureManager
extends Node

func _on_court_changed() -> void:
    for item_key in _expected_spawned_keys():
        if not _spawned.has(item_key):
            _spawn(item_key)
    for item_key in _spawned.keys():
        if not _is_still_on_court(item_key):
            _free(item_key)
```

On free: `queue_free`. The position becomes available for the next occupant.

---

## Prop conventions

Every fixture prop's root script:

- Adds itself to the `&"fixture"` group on `_ready`.
- Owns its own state (jukebox `is_playing`, bot dock `is_active`).
- Hooks runtime systems it overrides directly.
- Unhooks cleanly on `queue_free`.

Fixtures and roles are loosely coupled: fixtures know where they spawned, roles know occupancy, `FixtureManager` is the glue.

---

## Character areas vs item fixtures

| | Character areas | Item fixtures |
|---|---|---|
| Examples | Shop, Workshop | Bot dock, jukebox |
| Gating | `unlocked_characters` | Item on the court |
| Lifecycle | Top-level child scenes, hidden until unlock | Spawned and freed by `FixtureManager` |

---

## Rough ticket outline

Not filing yet.

1. `Fixture` resource, `FixtureManager`, prop group convention.
2. Per-fixture prop scenes alongside each item (see `08-bot.md`).
