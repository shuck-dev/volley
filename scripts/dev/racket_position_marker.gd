@tool
class_name RacketPositionMarker
extends Marker2D

@export var racket_collision: CollisionShape2D


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var shape: RectangleShape2D = racket_collision.shape
	if shape == null:
		return
	var half_width: float = shape.size.x * 0.5
	var half_height: float = shape.size.y * 0.5
	draw_line(Vector2(half_width, -half_height), Vector2(half_width, half_height), Color.RED, 0.5)
