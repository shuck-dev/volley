# Racket hitbox position per animation state

Resolves SH-518 (visual tuning of the racket collision zone during Sam's
low-swing pose). Continues `2026-06-06-paddle-animation-collision-spike.md`,
which decided the CharacterBody2D body collider stays fixed across states.
That decision stands. This doc addresses a separate shape: the RacketHitbox
Area2D, the mid-body zone that detects the ball and feeds the return-angle
calculus. That zone shifts with the crouch pose and the prior decision did not
cover it.

## Decision

Marker2D child nodes under a `RacketPositions` container in the paddle scene,
one per animation state that needs a distinct racket position. On state change,
copy the matching marker's local position to `racket_hitbox.position`. States
without a marker fall back to the scene-authored RacketHitbox position.

The per-frame Y-override in `player_paddle.gd._physics_move` is removed
entirely. The racket position is set once on state transition, not recomputed
every physics tick.

## Why Marker2D

**Visual.** The designer selects a marker in the scene tree, sees a cross-gizmo
in the 2D viewport, and drags it to where the racket should sit for that state.
No number guessing, no animation scrubbing, no resource-file round trips.

**Precedent.** The paddle scene already uses Node2D anchors as positional
references: `AnkleAnchor` at `[0, 24]`, `GripAnchor` at `[-12, 0]`,
`WristAnchor` at `[-12, -10]`. The `RacketPositions` container extends the same
pattern.

**Hook fits naturally.** `_on_animation_state_changed` already fires on every
state transition via the paddle animation state machine. Adding a racket-position
lookup there is a two-line addition with no structural refactoring.

**Dev panel survives.** The existing `set_racket_position_x` and
`set_racket_position_y` on `paddle.gd` become additive offsets applied on top
of the per-state position. The spinboxes that appeared broken for Y (the
`_physics_move` override was writing over them every frame) now work as live
fine-tune controls.

## Why not the alternatives

| Approach | Rejected because |
|---|---|
| `@export` dictionary per state | Not visually tunable. The designer types coordinates blind in the inspector, no viewport feedback. |
| AnimationPlayer on RacketHitbox position | Duplicates the SpriteFrames animation infrastructure. Seven animation states require two systems kept in sync. A new state means updating both. Adds a timeline for what is fundamentally a single-position-per-state problem. |
| Custom Resource with Vector2 per state | Another file type to manage. Still no viewport visual. Over-engineered for seven positions. |

## Scene shape

```
PlayerPaddle (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── RacketPositions (Node2D)
│   ├── RPos_ready_grounded (Marker2D)
│   ├── RPos_ready_flying (Marker2D)
│   ├── RPos_flying_up (Marker2D)
│   ├── RPos_flying_down (Marker2D)
│   ├── RPos_swing_grounded (Marker2D)
│   ├── RPos_low_swing_grounded (Marker2D)
│   └── RPos_swing_flying (Marker2D)
├── RacketHitbox (Area2D)
│   └── RacketCollision (CollisionShape2D)
├── ...existing nodes...
```

All seven markers exist in the scene. States that share the default position
can omit their marker; the code falls back to the scene-authored RacketHitbox
position. The container keeps the tree tidy.

## Code shape

`player_paddle.gd` overrides a new virtual `_apply_racket_position(state)` on
the base class. The override collects Marker2D children from `RacketPositions`
at `_ready`, maps them by state name, and on each call copies the matching
marker's `position` to `racket_hitbox.position`.

The base class `paddle.gd` calls `_apply_racket_position(state)` from
`_on_animation_state_changed` after the sprite animation plays. The default
implementation is a no-op; partner paddles inherit it unchanged.

`_base_racket_y` and the crouch-position formula in `_physics_move` are
removed. The racket position is no longer touched in the physics loop.

## Implementation

SH-xxx (child of SH-518).
