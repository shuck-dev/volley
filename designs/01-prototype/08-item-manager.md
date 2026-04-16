# ItemManager: Data Model and Runtime

Runtime layer behind `08-items.md`. Role logic lives in `08-roles.md`, fixtures in `08-fixtures.md`, kit passive FP in `08-kit.md`, balls in `08-balls.md`.

**Dependencies:** Effect System (`07`), Items (`08-items.md`), World (`08-world.md`), Shop Drag-and-Drop (`04-shop-drag-drop.md`).

---

## Data model

Ownership lives on `ProgressionData.item_levels`. Court placement is a second field; kit membership is derived.

```gdscript
# role (ball/court/equipment) -> ordered array of item keys
var on_court: Dictionary[StringName, Array] = {}

var destroyed_items: Array[String] = []
var kit_accumulated_points: float = 0.0   # see 08-kit.md
var kit_last_tick_unix: int = 0
```

Destruction sets `item_levels[key] = 0` and appends to `destroyed_items`.

### Derived queries

```gdscript
func get_court_items() -> Array[String]
func get_kit_items() -> Array[String]
func is_on_court(item_key: String) -> bool
func role_occupants(role: StringName) -> Array[String]
```

Court/kit state stays on `ItemManager` (not a new autoload) because effect registration, save triggers, and balance arithmetic already live there.

---

## Move to court, move to kit

```gdscript
func move_to_court(item_key: String) -> bool
func move_to_kit(item_key: String) -> bool
```

### Move-to-court

1. Reject if destroyed, not owned, already on the court, or role cooldown is active.
2. Charge `court_swap_friendship_cost`; reject if insufficient.
3. Append to `on_court[role]`.
4. `_effect_manager.register_source(item, level)`.
5. `FixtureManager` spawns the fixture if the item has one (see `08-fixtures.md`).
6. Start the role cooldown. Save. Emit `court_changed`.

### Move-to-kit

Reverse: unregister effects, free fixture, remove from `on_court`, start role cooldown. No FP cost.

### `_set_level` refactor

- `purchase()` writes `item_levels` only. If the item is on the court, re-register its effects at the new level.
- `take()` stays inert.
- `move_to_court` is the only path that registers effects.

Dev panel uses `purchase_and_place(key)` to preserve the one-click flow.

### SH-93

Closes when `move_to_court` lands. `ClearanceBox.accept` stays inert by design; the player places the item from the kit.

---

## Swap cost and role cooldown

```
court.swap_friendship_cost: int = 0
court.swap_cooldown_seconds: float = 0.0
```

Hot-reloadable via `ConfigHotReload`.

Per-role cooldown lives in memory only (`_role_cooldowns_until: Dictionary[StringName, float]`).

UI: thin fill on the role marker while cooling; FP cost shown on the drag preview.

---

## Signals

```
signal court_changed
signal role_cooldown_changed(role: StringName)
```

Existing `friendship_point_balance_changed` and `item_level_changed` are unchanged.

---

## Testing

- `move_to_court` / `move_to_kit` state transitions and FP debits.
- Role occupancy (append, remove, overflow stack).
- Kit passive FP (see `08-kit.md`).
- Ball reconciliation (see `08-balls.md`).

---

## Rough ticket outline

Not filing yet.

1. Court/kit data model, derived queries, signals.
2. `move_to_court` / `move_to_kit`, `_set_level` refactor, dev-panel update, SH-93 close-out.
3. Swap cost + per-role cooldown config.
