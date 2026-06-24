@tool
class_name RacketPositionMarker
extends Marker2D

@export var racket_collision: CollisionShape2D


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var width: float = _collision_width()
	var half_width: float = width * 0.5
	draw_line(Vector2(-half_width, 0), Vector2(half_width, 0), Color.RED, 3.0)


func _collision_width() -> float:
	if racket_collision == null or not (racket_collision.shape is RectangleShape2D):
		return 20.0
	return (racket_collision.shape as RectangleShape2D).size.x
