class_name SoulBoundOverlay
extends Node2D

## Debug overlay: horizontal line at the soul bound marker.

const BOUND_LINE_COLOR := Color(1.0, 0.7, 0.2, 0.4)

var dev_visible: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	z_index = 4095
	top_level = true
	visible = false
	add_to_group(&"dev_overlays")


func set_dev_visible(value: bool) -> void:
	dev_visible = value
	visible = value

	if value:
		queue_redraw()


func _process(_delta: float) -> void:
	if dev_visible:
		queue_redraw()


func _find_court() -> Court:
	var root := get_tree().current_scene
	if root == null:
		return null
	for child in root.get_children():
		if child is Court:
			return child
	return null


func _draw() -> void:
	var court: Court = _find_court()

	if court == null or court.soul_bound == null or court.court_config == null:
		return

	var bound_y: float = court.soul_bound.global_position.y
	var court_width: float = court.court_config.court_width
	var left: Vector2 = _project_to_canvas(Vector2(-court_width * 0.5, bound_y))
	var right: Vector2 = _project_to_canvas(Vector2(court_width * 0.5, bound_y))

	draw_line(left, right, BOUND_LINE_COLOR, 2.0)


func _project_to_canvas(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos
