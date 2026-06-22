# Racket hitbox position per animation state

The racket hitbox (RacketHitbox Area2D, the mid-body zone that detects the
ball) shifts with Sam's crouch pose. The CharacterBody2D body collider stays
fixed per `2026-06-06-paddle-animation-collision-spike.md`. The prior spike
anticipated this in passing: "if a future ready pose ever extends the paddle's
reach, the collider question reopens for that state alone."

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
`set_racket_position_y` on `paddle.gd` store an additive offset applied on top
of the per-state marker position. Each state transition recomputes
`racket_hitbox.position = marker.position + offset`, preserving the offset
across states. The spinboxes that appeared broken for Y (the `_physics_move`
override was writing over them every frame) now work as live fine-tune controls.

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
│   ├── RPos_ready_grounded (RacketPositionMarker)
│   ├── RPos_ready_flying (RacketPositionMarker)
│   ├── RPos_flying_up (RacketPositionMarker)
│   ├── RPos_flying_down (RacketPositionMarker)
│   ├── RPos_swing_grounded (RacketPositionMarker)
│   ├── RPos_low_swing_grounded (RacketPositionMarker)
│   └── RPos_swing_flying (RacketPositionMarker)
├── RacketHitbox (Area2D)
│   └── RacketCollision (CollisionShape2D)
├── ...existing nodes...
```

All seven markers exist in the scene. States that share the default position
can omit their marker; the code falls back to the scene-authored RacketHitbox
position. The container keeps the tree tidy.

## Editor tool

The Marker2D crosshair alone does not show the RacketHitbox extents. An editor
tool renders the collision shape so the designer sees the actual hitzone while
dragging.

A custom `RacketPositionMarker` class extends `Marker2D` with `@tool`:

```
@tool
class_name RacketPositionMarker
extends Marker2D

@export var collision_size := Vector2(20, 20)

func _draw() -> void:
	draw_rect(Rect2(-collision_size * 0.5, collision_size), Color.RED, false, 2.0)
```

- `collision_size` is set to match the RacketCollision RectangleShape2D.
- `_draw()` fires in the editor; the rectangle follows the marker around as the
  designer drags it.
- The colour and line weight are editor-only visualisation; they do not appear
  at runtime.
- The markers in the scene shape above use `RacketPositionMarker` instead of
  raw `Marker2D`.

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

## Out of scope

Restitution physics, `Paddle.get_half_height()`, and the body collider shape.
Those stay one fixed authored collider per the prior decision.
