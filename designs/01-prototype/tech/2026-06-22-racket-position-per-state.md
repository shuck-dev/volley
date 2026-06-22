# Racket hitbox position per animation state

The racket hitbox shifts with Sam's crouch pose. The body collider stays fixed
per `2026-06-06-paddle-animation-collision-spike.md`.

## Decision

A single `LowRacketAnchor` Marker2D child defines the low-swing racket position.
The scene-authored RacketHitbox position is the default. On state change the
paddle switches between the two.

The per-frame Y-override in `player_paddle.gd._physics_move` is removed. The
racket position is set on state transition, not every physics tick.

## Why Marker2D

The paddle scene already uses Node2D anchors (`AnkleAnchor`, `GripAnchor`,
`WristAnchor`). `LowRacketAnchor` extends the same pattern. The designer drags
the cross-gizmo in the 2D viewport to where the racket should sit during a low
swing.

## Editor tool

A `@tool` Marker2D subclass draws the collision rectangle so the designer sees
the actual hitzone while dragging:

```
@tool
class_name RacketPositionMarker
extends Marker2D

@export var collision_size := Vector2(20, 20)

func _draw() -> void:
	draw_rect(Rect2(-collision_size * 0.5, collision_size), Color.RED, false, 2.0)
```

`collision_size` matches the RacketCollision RectangleShape2D. The draw is
editor-only; it does not appear at runtime.

## Scene shape

```
PlayerPaddle (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── LowRacketAnchor (RacketPositionMarker)
├── RacketHitbox (Area2D)
│   └── RacketCollision (CollisionShape2D)
├── ...
```

## Code shape

`player_paddle.gd` overrides a virtual `_apply_racket_position(state)` on
`paddle.gd`. The override switches between the low anchor and the default:

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
`_on_animation_state_changed` after the sprite animation plays. Partner paddles
inherit the no-op default.

`_base_racket_y` and the crouch formula in `_physics_move` are removed.
