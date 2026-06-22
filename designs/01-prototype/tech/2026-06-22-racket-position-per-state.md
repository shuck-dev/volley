# Racket hitbox position per animation state

The racket hitbox (RacketHitbox Area2D, the mid-body zone that detects the
ball) shifts with Sam's crouch pose. The CharacterBody2D body collider stays
fixed per `2026-06-06-paddle-animation-collision-spike.md`. The prior spike
anticipated this in passing: "if a future ready pose ever extends the paddle's
reach, the collider question reopens for that state alone."

## Decision

A single `LowRacketAnchor` Marker2D child defines the low-swing racket position.
The scene-authored RacketHitbox position is the default for every other state.
On state change, the paddle switches between the two: the low anchor when the
state is crouch or low-swing, the default otherwise.

The per-frame Y-override in `player_paddle.gd._physics_move` is removed
entirely. The racket position is set on state transition, not recomputed every
physics tick.

## Why Marker2D

**Visual.** The designer selects the anchor in the scene tree, sees a cross-gizmo
in the 2D viewport, and drags it to where the racket should sit during a low
swing. No number guessing.

**Precedent.** The paddle scene already uses Node2D anchors as positional
references: `AnkleAnchor` at `[0, 24]`, `GripAnchor` at `[-12, 0]`,
`WristAnchor` at `[-12, -10]`. `LowRacketAnchor` extends the same pattern.

**Dev panel survives.** The existing `set_racket_position_x` and
`set_racket_position_y` on `paddle.gd` store an additive offset applied on top
of the anchor position. Each state transition recomputes
`racket_hitbox.position = anchor_position + offset`, preserving the offset
across states.

## Scene shape

```
PlayerPaddle (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── LowRacketAnchor (RacketPositionMarker)
├── RacketHitbox (Area2D)
│   └── RacketCollision (CollisionShape2D)
├── ...existing nodes...
```

## Editor tool

A custom `RacketPositionMarker` class extends `Marker2D` with `@tool`:

```
@tool
class_name RacketPositionMarker
extends Marker2D

@export var collision_size := Vector2(20, 20)

func _draw() -> void:
	draw_rect(Rect2(-collision_size * 0.5, collision_size), Color.RED, false, 2.0)
```

- `collision_size` matches the RacketCollision RectangleShape2D.
- `_draw()` fires in the editor; the rectangle follows the marker.
- Colour and line weight are editor-only; they do not appear at runtime.

## Code shape

`player_paddle.gd` overrides a virtual `_apply_racket_position(state)` on
`paddle.gd`. The override switches the racket position between the low anchor
and the default based on the state's crouch/lowness:

```
func _apply_racket_position(state: StringName) -> void:
	if state in _low_states:
		racket_hitbox.position = low_anchor.position
	else:
		racket_hitbox.position = _default_racket_pos
	racket_hitbox.position += _dev_offset
	_refresh_overlay_shapes()
```

The base class calls `_apply_racket_position(state)` from
`_on_animation_state_changed` after the sprite animation plays. The default
implementation is a no-op; partner paddles inherit it unchanged.

`_base_racket_y` and the crouch-position formula in `_physics_move` are
removed. The racket position is no longer touched in the physics loop.

## Out of scope

Restitution physics, `Paddle.get_half_height()`, and the body collider shape.
Those stay one fixed authored collider per the prior decision.
