@tool
class_name RacketPositionMarker
extends Marker2D

@export var racket_collision: CollisionShape2D


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var size: Vector2 = _collision_size()
	if size == Vector2.ZERO:
		return
	var half_width: float = size.x * 0.5
	var half_height: float = size.y * 0.5
	draw_line(Vector2(half_width, -half_height), Vector2(half_width, half_height), Color.RED, 0.5)


func _collision_size() -> Vector2:
	if racket_collision == null or not (racket_collision.shape is RectangleShape2D):
		return Vector2.ZERO
	return (racket_collision.shape as RectangleShape2D).size
