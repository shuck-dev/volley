class_name ColliderOverlay
extends Node2D

## Dev-only overlay that paints the paddle's collision rectangles ABOVE the sprite. Drawn from a
## dedicated child with a raised z_index because a CharacterBody2D's own _draw renders under its
## sprite child. Body and racket draw independently so each can be shown alone while tuning.

var _body_active: bool = false
var _racket_active: bool = false
var _body_size: Vector2 = Vector2.ZERO
var _body_offset: Vector2 = Vector2.ZERO
var _racket_size: Vector2 = Vector2.ZERO
var _racket_offset: Vector2 = Vector2.ZERO


func set_body_active(active: bool) -> void:
	_body_active = active
	queue_redraw()


func set_racket_active(active: bool) -> void:
	_racket_active = active
	queue_redraw()


func set_shapes(
	body_size: Vector2, body_offset: Vector2, racket_size: Vector2, racket_offset: Vector2
) -> void:
	_body_size = body_size
	_body_offset = body_offset
	_racket_size = racket_size
	_racket_offset = racket_offset
	queue_redraw()


func _draw() -> void:
	if _body_active and _body_size != Vector2.ZERO:
		draw_rect(Rect2(_body_offset - _body_size * 0.5, _body_size), Color(0.2, 0.6, 1.0, 0.35))

	if _racket_active and _racket_size != Vector2.ZERO:
		draw_rect(
			Rect2(_racket_offset - _racket_size * 0.5, _racket_size), Color(1.0, 0.4, 0.2, 0.5)
		)
