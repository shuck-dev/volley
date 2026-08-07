class_name RacketHitbox
extends Area2D

@export var collision: CollisionShape2D

var _shape: RectangleShape2D


func _ready() -> void:
	if collision.shape is RectangleShape2D:
		_shape = collision.shape


func get_half_height() -> float:
	if _shape != null:
		return _shape.size.y * 0.5
	return 0.0
