class_name ColliderOverlay
extends Node2D

## Dev-only overlay that paints the paddle's collision rectangles ABOVE the sprite. Drawn from a
## dedicated child with a raised z_index because a CharacterBody2D's own _draw renders under its
## sprite child. The paddle drives this via set_shapes / set_active; nothing renders unless active.

var _active: bool = false
var _body_size: Vector2 = Vector2.ZERO
var _racket_size: Vector2 = Vector2.ZERO
var _racket_offset: Vector2 = Vector2.ZERO


func set_active(active: bool) -> void:
	_active = active
	queue_redraw()


func set_shapes(body_size: Vector2, racket_size: Vector2, racket_offset: Vector2) -> void:
	_body_size = body_size
	_racket_size = racket_size
	_racket_offset = racket_offset
	queue_redraw()


func _draw() -> void:
	if not _active:
		return

	if _body_size != Vector2.ZERO:
		draw_rect(Rect2(-_body_size * 0.5, _body_size), Color(0.2, 0.6, 1.0, 0.35))

	if _racket_size != Vector2.ZERO:
		draw_rect(
			Rect2(_racket_offset - _racket_size * 0.5, _racket_size), Color(1.0, 0.4, 0.2, 0.5)
		)
