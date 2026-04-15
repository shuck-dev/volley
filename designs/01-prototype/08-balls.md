# Balls on the Court

The `ball` role and its reconciliation. Defines how ball items contribute permanent balls to the court, how effect-driven temporary balls sit alongside them, and why the two sets are managed separately.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), Effect System (`07`).

---

## Narrative

Ball items sit in the `ball` role. Each one adds a ball to the court: Training Ball alone puts one ball out; Training Ball plus The Stray put two out; three ball items put three out. Taking a ball item back to the kit removes that ball from the court.

Item effects that spawn additional balls (e.g. The Stray's frenzy outcome) create **temporary** balls on top of the permanent ones. Temporary balls are cleared by their expiry condition (miss during frenzy, etc.). The permanent balls remain throughout.

Example: Training Ball and The Stray both on the court = two balls at all times. Frenzy triggers on personal best, spawning additional temporary balls. Miss during frenzy clears the temps; the two permanents stay.

---

## The `ball` role

The `ball` role is additive (see `08-roles.md`). Every item authored with `role = &"ball"` adds a ball to the court when placed there. The ball manager reconciles visible balls against the contents of `on_court[&"ball"]`.

### `ItemDefinition` implications

Any item whose `role == &"ball"` contributes a ball. No separate `spawns_permanent_ball` flag is needed: the role is the flag.

---

## `BallReconciler`

A node on the court scene that listens to `ItemManager.court_changed` and reconciles the permanent-ball set:

```
expected_permanent_count = size of on_court[&"ball"]
current_permanent_count  = count of live balls tagged "permanent"
diff and spawn/despawn to match
```

Temporary balls (from effects like The Stray's frenzy) are tagged separately and are not touched by the reconciler; they clear on their own expiry.

---

## Effect-driven temporary balls

Effects that spawn temporary balls use a new outcome type alongside `StatOutcome`:

```gdscript
# scripts/items/effect/outcomes/spawn_ball_outcome.gd
class_name SpawnBallOutcome
extends Outcome

@export var count: int = 1
@export var expiry: StringName = &"on_miss"    # matches existing trigger types
@export var speed_override: float = 0.0        # 0 = inherit current ball speed
```

Temporary balls carry their expiry condition. The `BallReconciler` only manages the permanent set; temporary balls are owned by the effect system.

---

## Why split permanent and temporary

Permanent and temporary balls have different authoring surfaces (role membership vs effect outcome), different lifecycles (court state vs effect condition), and different owners (reconciler vs effect system). Keeping them parallel lets each stay local to its trigger.

---

## Testing

Unit-testable without a Viewport:

- Ball reconciliation (adding / removing / multiple ball items).
- `SpawnBallOutcome` creates temporary balls that clear on the authored expiry.
- Reconciler does not touch temporary balls.

---

## Rough ticket outline

Not filing yet.

1. `BallReconciler`, `SpawnBallOutcome`, authoring for Training Ball and The Stray against the `ball` role.
