# Fixtures

Court items (role = `court`) with a physical prop carry a `Fixture` resource. `FixtureManager` spawns and frees the prop as the item moves between the floor and a court marker.

Ball items and equipment items do not use fixtures; their parent scenes (ball rack and court for balls; gear rack and paddle for equipment) host their props directly.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), Venue (`08-venue.md`).

---

## Authoring

```gdscript
# ItemDefinition
@export var role: StringName       # ball, court, or equipment
@export var fixture: Fixture       # optional; used only for court items

class_name Fixture
extends Resource

@export var prop_scene: PackedScene
@export var dock_marker: StringName    # override; e.g. the bot dock
```

Runtime state, signals, and system overrides live on the prop scene's root script.

---

## Position

Court fixtures spawn at the next free marker under `Roles/Court` (see `08-roles.md`). `dock_marker` forces a named marker regardless of occupancy order.

---

## FixtureManager

Lives on the court scene. Subscribes to `ItemManager.court_changed`; spawns and frees court props to match `on_court[&"court"]`.

```gdscript
class_name FixtureManager
extends Node

func _on_court_changed() -> void:
    for item_key in _expected_court_spawned_keys():
        if not _spawned.has(item_key):
            _spawn(item_key)
    for item_key in _spawned.keys():
        if not _is_still_on_court(item_key):
            _free(item_key)
```

On free: `queue_free`. The marker becomes available for the next occupant.

---

## Prop conventions

Every court fixture prop's root script:

- Adds itself to the `&"fixture"` group on `_ready`.
- Owns its own state (jukebox `is_playing`, bot dock `is_active`).
- Hooks runtime systems it overrides directly.
- Unhooks cleanly on `queue_free`.

---

## Character areas vs item fixtures

| | Character areas | Item fixtures |
|---|---|---|
| Examples | Shop, Workshop | Bot dock, jukebox |
| Role | n/a | `court` only |
| Gating | `unlocked_characters` | Item on the court |
| Lifecycle | Top-level child scenes, hidden until unlock | Spawned and freed by `FixtureManager` |

---

## Rough ticket outline

Not filing yet.

1. `Fixture` resource, `FixtureManager`, prop group convention.
2. Per-fixture prop scenes alongside each court item (see `08-bot.md`).
