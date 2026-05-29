@tool
class_name VenueBoundDebugDraw
extends StaticBody2D

## Editor-and-debug-only outline of a venue bound; never drawn in a release build.
@export var debug_color: Color = Color(1.0, 0.2, 0.2, 0.5)
@export var collision_shape: CollisionShape2D


func _ready() -> void:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		return

	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		return

	if collision_shape == null:
		return

	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle == null:
		return

	var bounds := Rect2(collision_shape.position - rectangle.size * 0.5, rectangle.size)
	draw_rect(bounds, debug_color)
