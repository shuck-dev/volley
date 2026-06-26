class_name DevBouncePanel
extends VBoxContainer

## Debug numeric readout of paddle-bounce tunables plus per-hit resolved values.

var _drag := DraggableBehavior.new()
var _tracker: BallReconciler
var _ball_subscriptions: Dictionary = {}
var _label_max_degrees: Label
var _label_english: Label
var _label_last_hit: Label
var _last_offset_norm: float = 0.0
var _last_target_angle_deg: float = 0.0
var _last_incoming_y_sign: float = 0.0
var _has_last_hit: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 2)
	resized.connect(queue_redraw)
	_build_labels()
	_build_checks()

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


func _process(_delta: float) -> void:
	if not visible:
		return
	_refresh_tunables()


func _draw() -> void:
	pass


func _build_labels() -> void:
	_label_max_degrees = _make_label()
	add_child(_label_max_degrees)
	_label_english = _make_label()
	add_child(_label_english)
	_label_last_hit = _make_label()
	_label_last_hit.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	add_child(_label_last_hit)
	_refresh_tunables()
	_refresh_last_hit()


func _make_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	return label


func _refresh_tunables() -> void:
	var max_degrees: float = Stats.resolve(
		GameRules.paddle.paddle_return_angle_max_degrees, &"paddle_return_angle_max_degrees"
	)
	var english: float = Stats.resolve(
		GameRules.paddle.paddle_english_coefficient, &"paddle_english_coefficient"
	)
	_label_max_degrees.text = "return_angle_max: %.1f deg" % max_degrees
	_label_english.text = "english_coef: %.4f" % english


func _refresh_last_hit() -> void:
	if not _has_last_hit:
		_label_last_hit.text = "last_hit: (none)"
		return
	_label_last_hit.text = (
		"last_hit: off=%+.2f  angle=%+.1f deg  in_y=%+.0f"
		% [_last_offset_norm, _last_target_angle_deg, _last_incoming_y_sign]
	)


func _on_ball_added(ball: Ball) -> void:
	if ball == null or _ball_subscriptions.has(ball):
		return

	if ball.effect_processor == null:
		await get_tree().process_frame

		if not is_instance_valid(ball) or ball.effect_processor == null:
			return
	var callable := _on_bounce_resolved
	ball.effect_processor.bounce_resolved.connect(callable)
	_ball_subscriptions[ball] = callable


func _on_ball_removed(ball: Ball) -> void:
	if not _ball_subscriptions.has(ball):
		return
	var callable: Callable = _ball_subscriptions[ball]

	if (
		is_instance_valid(ball)
		and ball.effect_processor != null
		and ball.effect_processor.bounce_resolved.is_connected(callable)
	):
		ball.effect_processor.bounce_resolved.disconnect(callable)
	_ball_subscriptions.erase(ball)


func _on_bounce_resolved(
	_struck_paddle: Paddle,
	offset_norm: float,
	target_angle: float,
	incoming_y_sign: float,
	_horizontal_sign: float,
) -> void:
	_last_offset_norm = offset_norm
	_last_target_angle_deg = rad_to_deg(target_angle)
	_last_incoming_y_sign = incoming_y_sign
	_has_last_hit = true
	_refresh_last_hit()


func _build_checks() -> void:
	_add_checkbox("Show Cone Overlay", _on_cone_toggled)
	_add_checkbox("Show Soul Bound", _on_soul_bound_toggled)
	_add_checkbox("Show Arc Travel", _on_arc_travel_toggled)
	_add_checkbox("Cone follows last hit", _on_cone_follow_toggled)


func _add_checkbox(text: String, handler: Callable) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.button_pressed = false
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(handler)
	add_child(checkbox)


func _on_cone_toggled(pressed: bool) -> void:
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay is DevBounceOverlay:
			overlay.set_dev_visible(pressed)
			return


func _on_soul_bound_toggled(pressed: bool) -> void:
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay is SoulBoundOverlay:
			overlay.set_dev_visible(pressed)
			return


func _on_arc_travel_toggled(pressed: bool) -> void:
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay is ArcTravelOverlay:
			overlay.set_dev_visible(pressed)
			return


func _on_cone_follow_toggled(pressed: bool) -> void:
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay is DevBounceOverlay:
			overlay.follow_last_hit = pressed
			overlay.queue_redraw()
			return
