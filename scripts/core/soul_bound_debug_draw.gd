class_name SoulBoundDebugDraw
extends Node2D

@export var debug_color: Color = Color(1.0, 0.7, 0.2, 0.4)
@export var bound_y: float = 0.0
@export var court_width: float = 600.0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
	visible = false


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if court_width <= 0.0:
		return

	var half_width: float = court_width * 0.5
	var from := Vector2(-half_width, bound_y)
	var to := Vector2(half_width, bound_y)
	draw_line(from, to, debug_color, 2.0)
