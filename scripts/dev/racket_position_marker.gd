@tool
class_name RacketPositionMarker
extends Marker2D


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half_width: float = _collision_width() * 0.5
	draw_line(Vector2(-half_width, 0), Vector2(half_width, 0), Color.RED, 3.0)


func _collision_width() -> float:
	var parent: Node = get_parent()
	if parent == null:
		return 20.0
	var collision: CollisionShape2D = parent.get_node_or_null("RacketHitbox/RacketCollision")
	if collision == null or not (collision.shape is RectangleShape2D):
		return 20.0
	return (collision.shape as RectangleShape2D).size.x
