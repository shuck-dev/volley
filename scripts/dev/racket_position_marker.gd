@tool
class_name RacketPositionMarker
extends Marker2D

var collision_size := Vector2(20, 20)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half_width: float = collision_size.x * 0.5
	draw_line(Vector2(-half_width, 0), Vector2(half_width, 0), Color.RED, 3.0)
