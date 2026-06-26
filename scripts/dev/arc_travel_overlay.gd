class_name ArcTravelOverlay
extends Node2D

const TRAIL_MAX := 60
const TRAIL_COLOR := Color(0.4, 0.9, 0.4)
const LINE_WIDTH := 1.5
const ENVELOPE_COLOR := Color(0.4, 0.9, 0.4, 0.3)
const DASH_LENGTH := 6.0
const DASH_GAP := 4.0

var dev_visible: bool = false

var _tracker: BallReconciler
var _trail: Array[Vector2] = []
var _arc_ball: Ball


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	z_index = 4095
	top_level = true
	visible = false
	add_to_group(&"dev_overlays")

	_tracker = get_tree().get_first_node_in_group(&"ball_trackers") as BallReconciler

	if _tracker != null:
		_attach_to_tracker()
	else:
		get_tree().node_added.connect(_on_node_added_waiting_for_tracker)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree().node_added.is_connected(_on_node_added_waiting_for_tracker):
		get_tree().node_added.disconnect(_on_node_added_waiting_for_tracker)


func _on_node_added_waiting_for_tracker(node: Node) -> void:
	var tracker := node as BallReconciler
	if tracker == null:
		return
	get_tree().node_added.disconnect(_on_node_added_waiting_for_tracker)
	_tracker = tracker
	_attach_to_tracker()


func _attach_to_tracker() -> void:
	_tracker.ball_added.connect(_on_ball_added)
	_tracker.ball_removed.connect(_on_ball_removed)
	for ball in _tracker.get_balls():
		_on_ball_added(ball)


func _on_ball_added(_ball: Ball) -> void:
	pass


func _on_ball_removed(_ball: Ball) -> void:
	pass


func set_dev_visible(value: bool) -> void:
	dev_visible = value
	visible = value
	if value:
		queue_redraw()


func _process(_delta: float) -> void:
	if not dev_visible or _tracker == null:
		return

	_arc_ball = null
	for ball: Ball in _tracker.get_balls():
		if is_instance_valid(ball) and ball.play_state == Ball.PlayState.PLAY_ARC:
			_arc_ball = ball
			break

	if _arc_ball == null:
		if not _trail.is_empty():
			_trail.clear()
			queue_redraw()
		return

	_trail.append(_arc_ball.global_position)
	if _trail.size() > TRAIL_MAX:
		_trail.pop_front()
	queue_redraw()


func _draw() -> void:
	if _trail.size() < 2:
		return

	var trail_sz: int = _trail.size()
	for i in range(trail_sz - 1):
		var a: Vector2 = _project_to_canvas(_trail[i])
		var b: Vector2 = _project_to_canvas(_trail[i + 1])
		var alpha: float = float(i) / float(trail_sz)
		draw_line(a, b, TRAIL_COLOR * Color(1, 1, 1, alpha), LINE_WIDTH)

	if _arc_ball == null or _trail.size() < 2:
		return

	var apex_y: float = _arc_ball.bound_y - _arc_ball.court_config.physics.arc_height_max
	var trail_min_x: float = _trail[0].x
	var trail_max_x: float = _trail[0].x
	for p: Vector2 in _trail:
		if p.x < trail_min_x:
			trail_min_x = p.x
		if p.x > trail_max_x:
			trail_max_x = p.x

	var left: Vector2 = _project_to_canvas(Vector2(trail_min_x, apex_y))
	var right: Vector2 = _project_to_canvas(Vector2(trail_max_x, apex_y))
	var sx: float = left.x
	var ex: float = right.x
	var y: float = left.y
	var direction: float = signf(ex - sx)
	var d: float = sx

	while absf(d - ex) > DASH_LENGTH * 0.5:
		var dash_end: float = d + direction * DASH_LENGTH
		if (direction > 0 and dash_end > ex) or (direction < 0 and dash_end < ex):
			dash_end = ex
		draw_line(Vector2(d, y), Vector2(dash_end, y), ENVELOPE_COLOR, 1.0)
		d = dash_end + direction * DASH_GAP
		if (direction > 0 and d > ex) or (direction < 0 and d < ex):
			break


func _project_to_canvas(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos
