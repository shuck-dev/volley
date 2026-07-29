class_name DevBouncePanel
extends VBoxContainer

## Debug numeric readout of paddle-bounce tunables plus per-hit resolved values.

var _drag := DraggableBehavior.new()
var _paddle_subscriptions: Dictionary = {}
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


## Pushed by DevHud whenever the active paddle roster changes.
func set_paddles(paddles: Array[Paddle]) -> void:
	for paddle in _paddle_subscriptions.keys():
		var callable: Callable = _paddle_subscriptions[paddle]
		if is_instance_valid(paddle) and paddle.paddle_hit.is_connected(callable):
			paddle.paddle_hit.disconnect(callable)
	_paddle_subscriptions.clear()

	for paddle in paddles:
		if paddle == null or _paddle_subscriptions.has(paddle):
			continue
		var callable := _on_paddle_hit.bind(paddle)
		paddle.paddle_hit.connect(callable)
		_paddle_subscriptions[paddle] = callable


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


## Independently recomputes the bounce Ball just resolved, rather than Ball reporting it back.
func _on_paddle_hit(ball: Ball, struck_paddle: Paddle) -> void:
	if ball == null:
		return

	var result: PaddleBounceMath.Result = (
		PaddleBounceMath
		. resolve_bounce(
			ball.linear_velocity,
			ball.global_position,
			struck_paddle,
			Stats.resolve(
				GameRules.paddle.paddle_return_angle_max_degrees, &"paddle_return_angle_max_degrees"
			),
			Stats.resolve(
				GameRules.paddle.paddle_english_coefficient, &"paddle_english_coefficient"
			),
			Stats.resolve(
				GameRules.paddle.paddle_bounce_min_angle_degrees, &"paddle_bounce_min_angle_degrees"
			),
			Stats.resolve(
				GameRules.paddle.paddle_bounce_max_angle_degrees, &"paddle_bounce_max_angle_degrees"
			),
		)
	)
	if result == null:
		return

	_last_offset_norm = result.offset_norm
	_last_target_angle_deg = rad_to_deg(result.target_angle)
	_last_incoming_y_sign = result.incoming_y_sign
	_has_last_hit = true
	_refresh_last_hit()


func _build_checks() -> void:
	_add_checkbox("Show Cone Overlay", _on_cone_toggled)
	_add_checkbox("Show Soul Bound", _on_soul_bound_toggled)
	_add_checkbox("Show Arc Travel", _on_arc_travel_toggled)
	_add_checkbox("Show Ball Names", _on_ball_name_toggled)
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


func _on_ball_name_toggled(pressed: bool) -> void:
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay is BallNameOverlay:
			overlay.set_dev_visible(pressed)
			return
