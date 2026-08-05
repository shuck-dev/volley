class_name RacketHitbox
extends Area2D

## The racket zone that detects the ball and defines the contact-offset half-height; separate
## from the paddle's wall body. Owns its CollisionShape2D child directly so callers don't need
## to know or guess the child's node name.

@export var collision: CollisionShape2D

var _shape: RectangleShape2D


func _ready() -> void:
	if collision.shape is RectangleShape2D:
		_shape = collision.shape


func get_half_height() -> float:
	if _shape != null:
		return _shape.size.y * 0.5
	return 0.0
