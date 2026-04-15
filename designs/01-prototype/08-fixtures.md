# Fixtures: Physical Props on the Court

An item with a physical form on the court carries a `Fixture` resource. The fixture says what to spawn and where. `FixtureManager` spawns and frees props as items move between the court and the kit.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), World (`08-world.md`).

---

## What a fixture is

Items without a physical form (intrinsic upgrades, stat items) leave `fixture` null. Items with one carry a `Fixture`.

### `ItemDefinition` additions

```gdscript
@export var role: StringName                  # which role this item fills; see 08-roles.md
@export var fixture: Fixture                  # optional; spawns a prop when on the court
```

### The Fixture resource

A two-field resource. Pure authoring data.

```gdscript
class_name Fixture
extends Resource

@export var prop_scene: PackedScene    # what appears on the court
@export var dock_marker: StringName    # marker name on the court to spawn at (fallback)
```

All runtime state, interactivity, signals, and system overrides (music, input, etc.) live on the prop scene's root script. The `Fixture` resource is just "what to spawn and where."

The spawn position is normally resolved via `ItemManager.get_role_position(role, item_key)` (see `08-roles.md`). `dock_marker` is an override for items that need to point at a specific named marker regardless of role resolution (e.g. the bot dock).

---

## `FixtureManager`

A thin subscriber to `ItemManager.court_changed`, living on the court scene. Spawns and frees fixture props based on court presence.

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

Spawn position comes from the role resolver; the prop's `global_position` is set on spawn; the prop does not reposition itself afterward unless its own animation moves it.

On free, the prop is `queue_free`'d; the role position becomes available for the next occupant.

---

## Prop conventions

Every fixture prop's root script:

- Adds itself to the `&"fixture"` group on `_ready`.
- Owns its own state (the jukebox's `is_playing`, the bot dock's `is_active`).
- Hooks whatever runtime system it overrides directly, not through the item system.
- Frees cleanly on `queue_free`; unhooks overrides so nothing leaks after removal.

Props extend standard Godot node types and duck-type any shared behaviour via the `&"fixture"` group. Each prop stays independent, with only the group name as its shared surface.

Fixtures and roles are loosely coupled. A fixture does not know about its role directly; it only knows where it was spawned. A role does not know about fixtures; it only knows occupancy. `FixtureManager` is the glue.

---

## Character places vs item fixtures

The court holds two kinds of installed thing, on different lifecycles (see `08-world.md`):

- **Character places** (the shop, the workshop): gated by `unlocked_characters`. Child scenes of the court, hidden until their character arrives, visible from that moment on.
- **Item fixtures** (bot dock, jukebox): gated by court presence of the item carrying the fixture. Spawned by `FixtureManager`, freed when the item returns to the kit.

Both render into the same court scene. `FixtureManager` puts fixtures at their authored role markers; character places have their own dedicated positions authored into `court.tscn`.

---

## Rough ticket outline

Not filing yet.

1. `Fixture` resource, `FixtureManager`, prop group convention.
2. Per-fixture prop scene authoring (lands alongside each item that needs one; see `08-bot.md` for the bot dock).
