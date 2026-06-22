@tool
class_name RacketPositionMarker
extends Marker2D

@export var collision_size := Vector2(20, 20)


func _draw() -> void:
	draw_rect(Rect2(-collision_size * 0.5, collision_size), Color.RED, false, 2.0)
