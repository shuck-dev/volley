class_name ArcTravelOverlay
extends Node2D

const ARC_COLOR := Color(0.4, 0.9, 0.4)
const LINE_WIDTH := 1.5
const ENVELOPE_COLOR := Color(0.4, 0.9, 0.4, 0.3)
const DASH_LENGTH := 6.0
const DASH_GAP := 4.0
const ARC_ALPHAS := [0.15, 0.3, 0.5]
const MAX_ARCS := 3

var dev_visible: bool = false

var _tracker: BallReconciler
var _arcs: Array[Array] = []
var _current_arc: Array[Vector2] = []
var _was_in_arc: bool = false
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

	var ball: Ball = null
	for b: Ball in _tracker.get_balls():
		if is_instance_valid(b) and b.play_state == Ball.PlayState.PLAY_ARC:
			ball = b
			break

	var changed := false

	if ball == null:
		if _was_in_arc:
			_arcs.append(_current_arc)
			if _arcs.size() > MAX_ARCS:
				_arcs.pop_front()
			_current_arc = []
			changed = true
		else:
			if not _arcs.is_empty() or not _current_arc.is_empty():
				_arcs.clear()
				_current_arc = []
				changed = true
	else:
		_current_arc.append(ball.global_position)
		changed = true

	_was_in_arc = ball != null
	_arc_ball = ball

	if changed:
		queue_redraw()


func _draw() -> void:
	for arc_idx: int in range(_arcs.size()):
		var arc: Array = _arcs[arc_idx]
		if arc.size() < 2:
			continue
		var alpha: float = (
			ARC_ALPHAS[arc_idx]
			if arc_idx < ARC_ALPHAS.size()
			else ARC_ALPHAS[ARC_ALPHAS.size() - 1]
		)
		var color := Color(0.4, 0.9, 0.4, alpha)
		for i in range(arc.size() - 1):
			var a: Vector2 = _project_to_canvas(arc[i])
			var b: Vector2 = _project_to_canvas(arc[i + 1])
			draw_line(a, b, color, LINE_WIDTH)

	var curr_sz: int = _current_arc.size()
	if curr_sz >= 2:
		for i in range(curr_sz - 1):
			var a: Vector2 = _project_to_canvas(_current_arc[i])
			var b: Vector2 = _project_to_canvas(_current_arc[i + 1])
			var alpha: float = float(i) / float(curr_sz)
			var color := Color(0.4, 0.9, 0.4, alpha)
			draw_line(a, b, color, LINE_WIDTH)

	if _arc_ball == null:
		return

	var all_positions: Array[Vector2] = []
	for arc: Array in _arcs:
		for p: Vector2 in arc:
			all_positions.append(p)
	for p: Vector2 in _current_arc:
		all_positions.append(p)

	if all_positions.size() < 2:
		return

	var apex_y: float = _arc_ball.bound_y - _arc_ball.court_config.physics.arc_height_max
	var min_x: float = all_positions[0].x
	var max_x: float = all_positions[0].x
	for p: Vector2 in all_positions:
		if p.x < min_x:
			min_x = p.x
		if p.x > max_x:
			max_x = p.x

	var left: Vector2 = _project_to_canvas(Vector2(min_x, apex_y))
	var right: Vector2 = _project_to_canvas(Vector2(max_x, apex_y))
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
