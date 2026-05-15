# Gear

Tech spec for the gear capacity model in [`../design/gear.md`](../design/gear.md). Covers the capacity counter, per-item friendship cost, the drop target on the character, the `ItemManager` surface, save shape, and the timeout gate.

## Capacity and cost

`ItemDefinition` gains:

```gdscript
@export var friendship_cost: int = 1
```

`CharacterStatsConfig` (existing) gains:

```gdscript
@export var friendship_capacity: int = 3
```

The cap on day one is 3; training raises it. `ItemManager.get_friendship_capacity()` reads the active character's stat through the existing partner/character stat path; `ItemManager.get_friendship_used()` sums `friendship_cost` across currently equipped items. `get_friendship_remaining()` returns the difference.

## Drop target on the character

The character scene exposes one `Area2D` named `EquipDropTarget` covering the character's silhouette. A `CharacterDropTarget` (`scripts/items/drop_targets/character_drop_target.gd`) extends `DropTarget` and binds to it.

`can_accept(item)` returns true when:

- the item's `role == &"equipment"`,
- `friendship_remaining >= item.friendship_cost`,
- the timeout controller reports `AT_EQUIP_POSE`.

When `can_accept` returns false because of capacity, the controller still routes the release to the character; `accept` triggers a refusal animation and bounces the held token back to the rack. This keeps the gesture diegetic: the player drops on the character, the character refuses.

Per-item visual placement is per-item: each gear `ItemDefinition` declares an `anchor_node_path: NodePath` (or null for items with no anatomical anchor, like Cadence). On equip, the item's visual reparents to the named anchor on the character; if no anchor is set, the visual lands at a default carry position.

## ItemManager surface

```gdscript
func equip(item_key: String) -> bool
func unequip(item_key: String) -> bool
```

`equip` validates ownership and capacity headroom; on success, marks `state.equipped_items[item_key] = true`, calls `_effect_manager.register_source(item, get_level(item_key))`, and emits `item_placement_changed(item_key, EQUIPPED)`.

`unequip` clears the entry, calls `_effect_manager.unregister_source(item)`, and emits the same.

`activate` / `deactivate` retire for equipment; ball-role items keep the existing `_set_item_placement` path with `ON_COURT`.

A new signal `equip_refused(item_key, reason)` fires when capacity blocks an equip; the character scene listens and plays the refusal animation.

## Save shape

`ItemState.equipped_items: Dictionary[String, bool]` replaces the equipment side of `item_placements`. Ball-role placement keeps `item_placements` with `ON_COURT`.

Migration runs in `ItemState._post_load` under a save-version bump:

- For each entry in legacy `item_placements` whose value is `EQUIPPED`, set `equipped_items[item_key] = true`. Erase the legacy entry.
- When the cumulative cost of migrated items would exceed the active capacity, equip in declaration order until the cap is hit; remaining items return to `STORED` and the player re-equips through the rack on next timeout.

`LOOSE_IN_VENUE` and `STORED` keep their current shape.

## Timeout gate

The equip window opens on `TimeoutController.main_character_reached_equip_pose` and closes on `timeout_ended`. `CharacterDropTarget.can_accept` reads `TimeoutController.get_state() == AT_EQUIP_POSE` directly; off-court releases hit the venue or rack targets exactly as today.

Unequip is symmetric: dragging an equipped item back to the rack within the same window calls `ItemManager.unequip(item_key)` and frees its capacity. Outside the window, the character's drop target stays inert and the dragged item passes through to the next target in the priority list.
