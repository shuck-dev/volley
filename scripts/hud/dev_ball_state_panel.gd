class_name DevBallStatePanel
extends VBoxContainer

## Live per-ball play_state readout. Debug builds only.

var _tracker: BallReconciler
var _rows: Dictionary = {}
var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 2)
	resized.connect(queue_redraw)
	_add_header()

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


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not visible:
		return

	for ball: Ball in _rows.keys():
		if not is_instance_valid(ball):
			continue

		var row: Dictionary = _rows[ball]
		var label: Label = row["label"]
		label.text = _format_row(ball)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _add_header() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Ball States ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)


func _on_ball_added(ball: Ball) -> void:
	if ball == null or _rows.has(ball):
		return

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	label.text = _format_row(ball)
	add_child(label)

	var callable := _on_ball_state_changed.bind(ball)
	ball.play_state_changed.connect(callable)
	_rows[ball] = {"label": label, "callable": callable}


func _on_ball_removed(ball: Ball) -> void:
	if not _rows.has(ball):
		return

	var row: Dictionary = _rows[ball]
	var label: Label = row["label"]

	if is_instance_valid(ball) and ball.play_state_changed.is_connected(row["callable"]):
		ball.play_state_changed.disconnect(row["callable"])

	if is_instance_valid(label):
		label.queue_free()

	_rows.erase(ball)


func _on_ball_state_changed(_state: int, ball: Ball) -> void:
	if not _rows.has(ball) or not is_instance_valid(ball):
		return

	var row: Dictionary = _rows[ball]
	var label: Label = row["label"]
	label.text = _format_row(ball)


func _format_row(ball: Ball) -> String:
	var key: String = ball.item_key if ball.item_key != "" else "ball"
	var state_name: String = Ball.PlayState.find_key(ball.play_state)
	var final_mark: String = " FINAL" if ball.in_final else ""
	return (
		"%s  %s  T%d[%.0f-%.0f]%s  pos=(%d, %d)"
		% [
			key,
			state_name,
			ball.current_tier,
			ball.tier_floor,
			ball.tier_ceiling,
			final_mark,
			int(ball.position.x),
			int(ball.position.y)
		]
	)
