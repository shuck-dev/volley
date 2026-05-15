# Gear

Tech spec for the gear capacity model in [`../design/gear.md`](../design/gear.md). Covers the friendship cost on items, the capacity stat on the character, the drop target on the character, the `ItemManager` surface, and the timeout gate.

## Capacity and cost

`ItemDefinition` gains:

```gdscript
@export var friendship_cost: int = 1
```

`BaseStatsConfig` (existing) carries the cap. The current `kit_slots` field is reinterpreted as `friendship_capacity` (cost-weighted, replacing the count-of-items reading); the field itself can be renamed in the same change or kept under the existing name with the new meaning. The cap on day one is 3; training raises it.

`ItemManager.get_friendship_capacity()` reads the active character's stat. `ItemManager.get_friendship_used()` sums `friendship_cost` across items currently at the `EQUIPPED` placement. `get_friendship_remaining()` returns the difference.

## Drop target on the character

The character scene exposes one `Area2D` named `EquipDropTarget` covering the character's silhouette. A `CharacterDropTarget` (`scripts/items/drop_targets/character_drop_target.gd`) extends `DropTarget` and binds to it.

`can_accept(item)` returns true when:

- the item's `role == &"equipment"`,
- `friendship_remaining >= item.friendship_cost`,
- the timeout controller reports `AT_EQUIP_POSE`.

When `can_accept` returns false, the character's body acts as a wall to the held token: the home-and-loose collision-projection regime in [`../22-equip-loop-regime.md`](../22-equip-loop-regime.md) holds the token on the cursor, retries projection, and finally cancels back to source. Per-item visual placement: each gear `ItemDefinition` declares an `anchor_node_path: NodePath`; on equip, the item's visual reparents to the named anchor on the character.

When the rejection is specifically capacity-exceeded (the other two `can_accept` clauses passed), `CharacterDropTarget` emits `equip_refused(item_key, &"capacity_exceeded")` so the character scene can play a refusal animation. Other rejections (wrong role, wrong window) stay silent; the held token already communicates the projection failure.

## ItemManager surface

`equip(item_key)` and `unequip(item_key)` are public wrappers that gate equipment placement on capacity:

```gdscript
func equip(item_key: String) -> bool:
    var item := _get_item(item_key)
    if item.role != &"equipment":
        return false
    if get_friendship_remaining() < item.friendship_cost:
        equip_refused.emit(item_key, &"capacity_exceeded")
        return false
    return activate(item_key)

func unequip(item_key: String) -> bool:
    return deactivate(item_key)
```

`activate` and `deactivate` stay as the universal placement / effect-registration primitive (per [`04-effect-system.md`](04-effect-system.md)). Ball-role items continue calling `activate` directly. Equipment goes through `equip` / `unequip` so capacity is checked on the way in.

`equip_refused(item_key, reason: StringName)` signal: `reason` is currently `&"capacity_exceeded"` (the sole case). Listeners switch on it. New `reason` values land here as the model grows.

## Save shape

No change. Equipment placement continues to live in `ItemState.item_placements` with the `EQUIPPED` enum. `friendship_used` is derived per query; no new persisted field, no version bump, no wipe.

## Timeout gate

The equip window opens on `TimeoutController.main_character_reached_equip_pose` and closes on `timeout_ended`. `CharacterDropTarget.can_accept` reads `TimeoutController.get_state() == AT_EQUIP_POSE` directly. Off-court releases hit other targets.

Unequip is symmetric: dragging an equipped item back to the rack within the same window calls `unequip` and frees its capacity. Outside the window, the character's drop target stays inert and the dragged item passes through to the next target in the priority list.
