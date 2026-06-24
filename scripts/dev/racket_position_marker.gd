@tool
class_name RacketPositionMarker
extends Marker2D


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_line(Vector2(-20, 0), Vector2(20, 0), Color.RED, 3.0)
