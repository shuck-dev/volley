# Balls on the Court

The `ball` role adds permanent balls to the court. Effects add temporary ones.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`tech/06-roles.md`), Effect System (`tech/04-effect-system.md`).

---

## Permanent balls

Each item with `role = &"ball"` puts one ball on the court. Training Ball + The Stray = two balls at all times. The role is the flag; no `spawns_permanent_ball` field needed.

### Player interaction

The player can drag a ball to two destinations:

- **To the ball rack:** ball becomes inactive and waits on the rack for later use.
- **Directly into the court:** ball enters play immediately. `activate(key)` fires; `BallReconciler` spawns it from the court's ball-spawn origin.

Removing a live ball works the same way: drag it off the court back onto the `BallRack`. `deactivate(key)` fires; `BallReconciler` despawns it.

Both gestures happen live, without pausing. The main character keeps playing whatever balls remain.

### Rack slot assignment

The rack is a slot-indexed pool. The player drops "on the rack" and the rack decides which slot the ball lands in; the player cannot aim at a specific slot. Each ball entering STORED claims the lowest free slot index and holds it for the duration of that STORED span. Grabbing a ball frees its slot; the next store fills the lowest free index, which may be the just-vacated one or any other. The assignment is locked once made and never reshuffles while the rack is at rest; a ball that's already stored never moves slots on its own.

Same ball can land in different slots across stores. The mapping is per-STORED-span, not stable across the ball's lifetime.

### Auto-serve from the ball rack

When no balls are in play on the court, the main character walks to the ball rack, picks up the next available ball, and attempts a serve. This keeps the rally cycle going without requiring the player to manually drag a ball in. If the rack is empty (all balls are already on the court or none are owned), the character idles until a ball becomes available.

---

## Temporary balls

Effect outcomes (e.g. The Stray's frenzy) spawn temporary balls alongside permanent ones.

```gdscript
class_name SpawnBallOutcome
extends Outcome

@export var count: int = 1
@export var expiry: StringName = &"on_miss"    # existing trigger types
@export var speed_override: float = 0.0        # 0 = inherit current ball speed
```

Temporary balls clear on their expiry condition. Permanent balls persist.

The player can drag a live temporary ball off the court too. The drag is not a `deactivate` call (temporary balls are not owned items); it just triggers the same despawn path the ball would take on natural expiry. The spawning effect's state updates accordingly (e.g. frenzy ends if its last temp ball is pulled out).

---

## BallReconciler

Lives on the court scene. Listens to `ItemManager.court_changed`; reconciles live permanent balls against `on_court[&"ball"]`:

```
expected = size of on_court[&"ball"]
live     = count of balls tagged "permanent"
diff and spawn/despawn to match
```

Temporary balls are tagged separately and untouched by the reconciler. The player's drag-off on a permanent ball routes through `deactivate`; on a temporary ball it routes to that ball's normal despawn.

---

## Testing

- Reconciliation: add, remove, multiple ball items.
- Player drag-out on a permanent ball fires `deactivate`.
- Player drag-out on a temporary ball routes to that ball's normal despawn path; spawning effect state updates.
- `SpawnBallOutcome` spawns and clears on expiry.

---

## Rough ticket outline

Not filing yet.

1. `BallReconciler`, `SpawnBallOutcome`.
2. Drag handlers: rack to court; court to rack (permanent balls via `deactivate`, temporary balls via despawn path).
3. Training Ball and The Stray authored against the `ball` role.
