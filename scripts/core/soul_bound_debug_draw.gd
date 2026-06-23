@tool
class_name SoulBoundDebugDraw
extends Node2D

## Editor-and-debug-only line at the soul bound; never drawn in a release build.
@export var debug_color: Color = Color(1.0, 0.7, 0.2, 0.4)
@export var bound_y: float = 0.0
@export var court_width: float = 600.0


func _ready() -> void:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		return

	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		return
	if court_width <= 0.0:
		return

	var half_width: float = court_width * 0.5
	var from := Vector2(-half_width, bound_y)
	var to := Vector2(half_width, bound_y)
	draw_line(from, to, debug_color, 2.0)
