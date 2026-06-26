class_name ArcTravelOverlay
extends Node2D

## Debug overlay: arc trajectory markers above the soul bound.

const ARC_DOT_COLOR := Color(0.4, 0.9, 0.4, 0.6)
const ARC_DOT_RADIUS := 4.0
const DASH_LENGTH := 8.0
const DASH_GAP := 4.0

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
	var tracker: BallReconciler = (
		get_tree().get_first_node_in_group(&"ball_trackers") as BallReconciler
	)

	if tracker == null:
		return

	var court: Court = _find_court()
	var bound_y: float = 0.0

	if court != null and court.soul_bound != null:
		bound_y = court.soul_bound.global_position.y

	for ball: Ball in tracker.get_balls():
		if not is_instance_valid(ball) or ball.play_state != Ball.PlayState.PLAY_ARC:
			continue

		var pos: Vector2 = _project_to_canvas(ball.global_position)
		draw_circle(pos, ARC_DOT_RADIUS, ARC_DOT_COLOR)

		if bound_y != 0.0:
			var bound_screen_y: float = _project_to_canvas(Vector2(0.0, bound_y)).y
			var start_y: float = pos.y
			var end_y: float = bound_screen_y
			var total_dist: float = end_y - start_y
			var direction: float = signf(total_dist)
			var y: float = start_y

			while absf(y - end_y) > DASH_LENGTH * 0.5:
				var dash_end: float = y + direction * DASH_LENGTH

				if (direction > 0 and dash_end > end_y) or (direction < 0 and dash_end < end_y):
					dash_end = end_y
				draw_line(Vector2(pos.x, y), Vector2(pos.x, dash_end), ARC_DOT_COLOR, 1.0)
				y = dash_end + direction * DASH_GAP

				if (direction > 0 and y > end_y) or (direction < 0 and y < end_y):
					break


func _project_to_canvas(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos
