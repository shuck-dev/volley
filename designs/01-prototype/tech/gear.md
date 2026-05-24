# Gear

Tech spec for the gear capacity model. Covers the capacity stat on the character, the drop target on the character, the `ItemManager` surface, and the timeout gate.

## Capacity

`BaseStatsConfig.kit_slots` (existing) is the cap on equipped equipment items. Each equipped item counts as one. The cap on day one is 3; training raises it.

`ItemManager.get_kit_remaining()` returns `kit_slots` minus the count of items whose **persisted** placement is `EQUIPPED` (read `state.item_placements` directly, bypassing `_get_placement` so the runtime `LOOSE_IN_VENUE` overlay on a held-mid-drag item leaves the count unchanged; capacity reflects the kit on the body, frozen mid-gesture).

`kit_slots` is currently typed `float` for stat-percentage modifiers; callers floor it on read for the integer comparison.

## Drop target on the character

The character scene exposes one `Area2D` named `CharacterDropTarget` covering the character's silhouette. A `CharacterDropTarget` script (`scripts/items/drop_targets/character_drop_target.gd`) extends `DropTarget` and binds to it.

`can_accept(item_key, position, scale_factor)` (matching the `DropTarget` base signature) returns true when:

- the item resolved by `item_key` has `role == &"equipment"`,
- `kit_remaining >= 1`,
- the timeout controller reports `AT_EQUIP_POSE`.

The `position` and `scale_factor` arguments are unused for character drops (the `Area2D` already filters by overlap), kept for signature parity.

When `can_accept` returns false, the character's body acts as a wall to the held token: the home-and-loose collision-projection regime in [`../22-equip-loop-regime.md`](../22-equip-loop-regime.md) holds the token on the cursor, retries projection, and finally cancels back to source.

Capacity refusal is signalled by `ItemManager.equip_refused`, not by the drop target. The character scene (or any future animation listener) connects to `ItemManager`; the drop target stays silent. Other rejections (wrong role, wrong window) emit nothing; the held token already communicates the projection failure.

Each gear `ItemDefinition` declares an `anchor_node_path: NodePath` naming a `Node2D` on the character where its visual mounts. Anchors live on the character root (e.g. `PlayerPaddle`), never under the stat-scaled `Sprite`: anything reparented under `Sprite` inherits the `paddle_size`-driven `scale.y` and stretches. Empty path falls back to the character root.

## ItemManager surface

`equip(item_key)` and `unequip(item_key)` are public wrappers that gate equipment placement on capacity:

```gdscript
func equip(item_key: String) -> bool:
    var item := _get_item(item_key)
    if item.role != &"equipment":
        return false
    if get_kit_remaining() < 1:
        equip_refused.emit(item_key, &"capacity_exceeded")
        return false
    return activate(item_key)

func unequip(item_key: String) -> bool:
    return deactivate(item_key)
```

`activate` and `deactivate` stay as the universal placement / effect-registration primitive (per [`04-effect-system.md`](04-effect-system.md)). Ball-role items continue calling `activate` directly. Equipment goes through `equip` / `unequip` so capacity is checked on the way in.

`equip_refused(item_key, reason: StringName)` signal: `reason` is currently `&"capacity_exceeded"` (the sole case). Listeners switch on it. New `reason` values land here as the model grows.

## Save shape

No change. Equipment placement continues to live in `ItemState.item_placements` with the `EQUIPPED` enum. `kit_remaining` is derived per query; no new persisted field, no version bump, no wipe.

Over-capacity state across designer changes (an equipped item retired, `kit_slots` lowered) persists on load: equipped items stay equipped, and `equip` of any new item is blocked until the player unequips enough to fit. The kit on the body is preserved; the gate is only on adding more.

## Timeout gate

The equip window opens on `TimeoutController.main_character_reached_equip_pose` and closes on `timeout_ended`. `CharacterDropTarget.can_accept` reads `TimeoutController.get_state() == AT_EQUIP_POSE` directly. Off-court releases hit other targets.

Unequip is symmetric: dragging an equipped item back to the rack within the same window calls `unequip` and frees its slot. Outside the window, the character's drop target stays inert and the dragged item passes through to the next target in the priority list.

The rack-side gate is also symmetric. `RackDropTarget` (equipment role only) refuses drops while a rally is in progress (`TimeoutController.IDLE` and at least one ball in `PLAY_NORMAL` / `PLAY_ARC`). Removal during timeout, between rallies, and initial setup still lands. The shared check lives on `RallyGate.is_rally_in_progress`. The dev panel's per-item remove-level button uses the same gate so destruction paths cannot desync the effect system mid-rally.
