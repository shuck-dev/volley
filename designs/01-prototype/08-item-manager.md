# ItemManager: Data Model and Runtime

Runtime layer behind `08-items.md`. Role logic lives in `08-roles.md`, fixtures in `08-fixtures.md`, kit passive FP in `08-kit.md`, balls in `08-balls.md`.

**Dependencies:** Effect System (`07`), Items (`08-items.md`), Venue (`08-venue.md`), Shop Drag-and-Drop (`04-shop-drag-drop.md`).

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

---

## Move to court, move to kit

```gdscript
func move_to_court(item_key: String) -> bool
func move_to_kit(item_key: String) -> bool
```

Both are called by drag-and-drop handlers (see `08-kit.md` for the player-side flow per role).

### Move-to-court

1. Reject if destroyed, not owned, already on the court, or role cooldown is active.
2. Append to `on_court[role]`.
3. `_effect_manager.register_source(item, level)`.
4. If `role == &"court"`, `FixtureManager` spawns the prop (see `08-fixtures.md`). For `ball` and `equipment`, the parent scene (ball rack or paddle) hosts the prop directly; no fixture manager involvement.
5. Start the role cooldown. Save. Emit `court_changed`.

Activation has no FP cost; the friction is the animation (on equipment) and the role cooldown.

### Move-to-kit

Applies to `ball` and `equipment` only. Reverse of move-to-court: unregister effects, remove from `on_court`, start role cooldown.

Court items never call `move_to_kit`. They leave the court only by entering the Tinkerer's queue (see `08-tinkerer.md`); on return from a level-up commission, `move_to_court` re-seats them.

### `_set_level` refactor

- `purchase()` writes `item_levels` only. If the item is on the court, re-register its effects at the new level.
- `take()` stays inert.
- `move_to_court` is the only path that registers effects.

Dev panel uses `purchase_and_place(key)` to preserve the one-click flow.

### SH-93

Closes when `move_to_court` lands. `ClearanceBox.accept` stays inert by design; the player drags the item from `BallRack` or `GearRack` to activate it.

---

## Role cooldown

```
court.swap_cooldown_seconds: float = 0.0
```

Hot-reloadable via `ConfigHotReload`.

Per-role cooldown lives in memory only (`_role_cooldowns_until: Dictionary[StringName, float]`).

UI: thin fill on the target surface while cooling.

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
3. Per-role cooldown config.
