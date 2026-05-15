# Per-Limb Gear

Tech spec for the slot model in [`../design/per-limb-gear.md`](../design/per-limb-gear.md). Covers data shape, drop targets, `ItemManager` surface, save migration, and the timeout gate.

## Slot identity

A slot is a `StringName` like `&"hand_left"`, `&"hand_right"`, `&"wrist_left"`, `&"wrist_right"`, `&"ankle_left"`, `&"ankle_right"`, `&"head"`. Names are flat; symmetry is a naming convention, and a symmetric pair is two slots that share a `kind`.

Per-character slot maps live on a `CharacterSlotConfig` resource (`scripts/items/character_slot_config.gd`), exported on the character scene. The resource holds an array of `SlotEntry` records:

```gdscript
class_name SlotEntry
extends Resource

@export var name: StringName        # &"hand_left"
@export var kind: StringName        # &"hand", &"wrist", &"ankle", &"head"
@export var anchor_path: NodePath   # path to the per-limb Area2D on the character
```

`ItemDefinition` declares acceptance through a new field:

```gdscript
@export var slot_kinds: Array[StringName] = []   # e.g. [&"ankle"] for ankle weights
```

A slot accepts an item when `item.role == &"equipment"` and `slot.kind in item.slot_kinds`. Empty `slot_kinds` on an equipment item is a config error caught by a project-wide validator.

## Drop-target node layout

Each anatomical anchor is an `Area2D` child of the character scene, named after its slot: `HandLeft`, `HandRight`, `WristLeft`, `WristRight`, `AnkleLeft`, `AnkleRight`, `Head`. Each anchor carries one `CollisionShape2D` sized to the limb silhouette and a `Sprite2D` for hover feedback (dim outline at rest, bright outline while a compatible drag is hovering).

A `LimbDropTarget` (`scripts/items/drop_targets/limb_drop_target.gd`) extends `DropTarget` and binds to one `SlotEntry`. Its `can_accept` returns true when:

- the dragged item's `slot_kinds` contains the slot's `kind`,
- the slot is currently empty in `ItemState.slot_occupants`,
- the timeout controller reports `AT_EQUIP_POSE`.

`accept` calls `ItemManager.equip(item_key, slot_name)`. Targets register with the existing `BallDragController` alongside the rack, court, shop, and venue targets; the first-`can_accept`-wins rule already in [`ball_drag_controller.gd`](../../../scripts/items/ball_drag_controller.gd) carries the new targets unchanged.

Hover feedback rides the controller's existing hover signal: each `LimbDropTarget` exposes its anchor sprite, and the controller toggles modulate on the slot whose `can_accept` returns true under the cursor.

## ItemManager surface

`activate(key)` and `deactivate(key)` stay for ball-role items, where the natural target is `ON_COURT` and slot identity is irrelevant. Equipment moves to a slot-aware pair:

```gdscript
func equip(item_key: String, slot_name: StringName) -> bool
func unequip(slot_name: StringName) -> bool
```

`equip` validates ownership, slot kind, and slot vacancy; on success, writes `state.slot_occupants[slot_name] = item_key`, calls `_effect_manager.register_source(item, get_level(item_key))`, and emits `item_placement_changed(item_key, EQUIPPED)` plus a new `slot_changed(slot_name, item_key)`.

`unequip` reads the occupant, erases the entry, calls `_effect_manager.unregister_source(item)`, and emits the same pair with an empty key.

`get_placement(key)` reports `EQUIPPED` when the item appears anywhere in `slot_occupants`. A new `get_slot(item_key) -> StringName` returns the holding slot or `&""`. The effect-manager registration path is identical to today's `_set_item_placement`; slot identity carries no weight inside the effect pipeline.

## Save shape

`ItemState.item_placements` retires for equipment. `ItemState.slot_occupants: Dictionary[StringName, String]` takes its place: slot name to item key. Ball-role placement keeps the existing `item_placements` entry with `ON_COURT`.

Migration runs in `ItemState._post_load` under a save-version bump:

- For each entry in legacy `item_placements` whose value is `EQUIPPED`, look up the item's first compatible slot on the active `CharacterSlotConfig` and write it to `slot_occupants`. Erase the legacy entry.
- Drop the legacy entry on the floor when no compatible slot exists in the current build (item retired, slot kind retired, or the character now lacks that limb). The item returns to `STORED` and the player re-equips through the rack on next timeout.

`LOOSE_IN_VENUE` and `STORED` keep their current shape.

## Timeout gate

The equip drag window opens on `TimeoutController.main_character_reached_equip_pose` and closes on `timeout_ended`. `LimbDropTarget.can_accept` reads `TimeoutController.get_state() == AT_EQUIP_POSE` directly; off-court releases hit the venue or rack targets exactly as today.

`unequip` is symmetric: dragging an item off a limb back to the rack is allowed in the same window. Outside the window, limb anchors stay inert and the dragged item passes through to the next target in the priority list.
