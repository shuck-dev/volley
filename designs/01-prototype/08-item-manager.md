# ItemManager: Data Model and Runtime

Implementation layer behind the item concept (`08-items.md`). Covers the data model, the move-to-court / move-to-kit flow, swap economics, signals, save handling, and testing. Role-specific logic is in `08-roles.md`; fixture spawning in `08-fixtures.md`; kit passive FP in `08-kit.md`; ball reconciliation in `08-balls.md`.

**Dependencies:** Effect System (`07`), Items (`08-items.md`), World (`08-world.md`), Shop Drag-and-Drop (`04-shop-drag-drop.md`).

---

## Data model

Ownership lives on `ProgressionData.item_levels: Dictionary[String, int]`. The court/kit split is expressed as a second field that says which owned items are currently active on the court and in which role. Kit membership is derived: everything owned, not on the court, not destroyed.

### New `ProgressionData` fields

```gdscript
# Items placed on the court, keyed by their authored role.
# For exclusive roles (paddle_handle, etc.): role -> single item key.
# For additive roles (ball, court_side, court_surface): role -> array of item keys.
var on_court: Dictionary[StringName, Variant] = {}

var destroyed_items: Array[String] = []   # Permanently removed at the Tinkerer
var kit_accumulated_points: float = 0.0   # Unclaimed passive FP (see 08-kit.md)
var kit_last_tick_unix: int = 0           # Wall-clock seconds at last tick commit
```

The `on_court` dictionary is the single source of truth for active items and their positions. The kit is derived: every owned, non-destroyed item whose key is not in `on_court` is in the kit.

`destroyed_items` prevents a destroyed item reappearing if `item_levels` is ever re-derived. Destruction also sets `item_levels[key] = 0`; the list is the durable record.

Swap cooldowns are session-only; see below.

### Derived queries

```gdscript
func get_court_items() -> Array[String]              # flattened from on_court
func get_kit_items() -> Array[String]                # owned + not on court + not destroyed
func is_on_court(item_key: String) -> bool
func role_occupants(role: StringName) -> Array[String]
```

### Why extend `ItemManager` rather than add a new manager

`ItemManager` already owns item ownership, effect registration, save triggers, and balance arithmetic. Court/kit membership is a thin layer over those. Splitting it into a new autoload duplicates the effect registration path and forces cross-autoload save ordering. A single autoload with grouped sections stays under ~300 lines and keeps save atomicity trivial.

---

## Move to court, move to kit

Activation and deactivation run through one pair of methods. Placing an item on the court registers its effects and spawns its fixture (if any) at its authored role. Returning it to the kit unregisters the effects and frees the fixture.

### Methods

```gdscript
func move_to_court(item_key: String) -> bool
func move_to_kit(item_key: String) -> bool
func swap_at_role(role: StringName, item_key: String) -> bool   # atomic exit + entry
```

### Move-to-court flow

1. Reject if the item is destroyed, not owned, already on the court, or its role cooldown is active.
2. Charge `court_swap_friendship_cost` from the balance. Reject if insufficient.
3. Resolve the item's authored `role`. If the role is exclusive and occupied, atomically move the current occupant to the kit (swap). Capacity rules live in `08-roles.md`.
4. Add the item to `on_court[role]` (single or array, per role kind).
5. Call `_effect_manager.register_source(item, level)`.
6. If the item has a fixture, `FixtureManager` spawns it at the role's marker (see `08-fixtures.md`).
7. Start the role's cooldown. Save.
8. Emit `court_changed`.

### Move-to-kit flow

Same in reverse: unregister effects, free the fixture (if any), remove from `on_court`, start the role cooldown. No FP cost on move-to-kit alone; the cost is attached to entering the court.

### `swap_at_role` (atomic)

A single gesture that moves a new item onto the court at a role while moving the current occupant back to the kit. One signal emission, one save write.

### Refactor of `_set_level`

`_set_level` no longer eagerly registers effects. After this change:

- Levelling via `purchase()` writes `item_levels` only. If the item is currently on the court, the change triggers a re-register at the new level.
- `take()` keeps its current behaviour: writes `item_levels`, no registration.
- Activation is the only path that registers effects, via `move_to_court`.

The dev panel moves off `purchase()` to a dev-only `purchase_and_place(key)` that acquires the item and places it on the court. The one-click dev experience is preserved.

### SH-93 resolution

SH-93 (shop `take()` currently inert) closes when `move_to_court` lands. `ClearanceBox.accept` remains unchanged: `take()` stays inert by design. The player places the item on the court from the kit once acquired.

---

## Swap cost and per-role cooldown

Both values are tuning knobs per the canon doc. They live in the existing balance config.

### Config keys

```
court.swap_friendship_cost: int = 0      # Prototype starts free; Make Fun Pass raises it
court.swap_cooldown_seconds: float = 0.0 # Prototype starts at 0 for playtesting
```

Both hot-reload through `ConfigHotReload` so we can iterate without a restart.

### Per-role cooldown state

Held on `ItemManager` as `_role_cooldowns_until: Dictionary[StringName, float]`, keyed by role name. Not persisted. Cooldown is a moment-to-moment pressure on the move decision; persisting it across sessions blocks the player on launch for reasons they have forgotten.

### UI surface

Each role on the kit (and each target role on the court) shows a thin radial or linear fill while its cooldown is active. The FP cost is shown on the drag preview when a court-ward drag is in progress.

---

## Signals

```
signal court_changed                            # Any move-to-court / move-to-kit / swap
signal role_cooldown_changed(role: StringName)  # Cooldown start/expire
signal kit_points_ticked(item_key, amount)      # Audio hook; see 08-kit.md
```

Existing signals (`friendship_point_balance_changed`, `item_level_changed`) keep their semantics.

---

## Testing

Unit-testable without a Viewport:

- `move_to_court` / `move_to_kit` / `swap_at_role` state transitions and FP debits.
- Role capacity behaviour (exclusive swap, additive stacking, small-additive eviction).
- Kit passive FP rate arithmetic (see `08-kit.md`).
- Ball reconciliation (see `08-balls.md`).

End-to-end drag flows are manual play-test, matching the shop pattern.

---

## Rough ticket outline

Not filing yet.

1. `ItemManager` court/kit data model + derived queries and signals.
2. Move-to-court / move-to-kit / swap-at-role methods, `_set_level` refactor, dev-panel update, SH-93 close-out.
3. Swap cost + per-role cooldown config + signal surface.

Role, fixture, kit, ball, and shop/workshop tickets live in their own docs.
