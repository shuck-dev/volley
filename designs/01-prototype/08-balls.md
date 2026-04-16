# Balls on the Court

The `ball` role adds permanent balls to the court. Effects add temporary ones.

**Dependencies:** Items (`08-items.md`), ItemManager (`08-item-manager.md`), Roles (`08-roles.md`), Effect System (`07`).

---

## Permanent balls

Each item with `role = &"ball"` puts one ball on the court. Training Ball + The Stray = two balls at all times. Taking a ball item back to the kit removes that ball.

The role is the flag; no `spawns_permanent_ball` field needed.

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

---

## BallReconciler

Lives on the court scene. Listens to `ItemManager.court_changed`; reconciles live permanent balls against `on_court[&"ball"]`:

```
expected = size of on_court[&"ball"]
live     = count of balls tagged "permanent"
diff and spawn/despawn to match
```

Temporary balls are tagged separately and untouched by the reconciler.

---

## Testing

- Reconciliation: add, remove, multiple ball items.
- `SpawnBallOutcome` spawns and clears on expiry.
- Reconciler leaves temporary balls alone.

---

## Rough ticket outline

Not filing yet.

1. `BallReconciler`, `SpawnBallOutcome`, Training Ball and The Stray authored against the `ball` role.
