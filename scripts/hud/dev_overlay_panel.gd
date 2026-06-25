class_name DevOverlayPanel
extends VBoxContainer

var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 2)
	resized.connect(queue_redraw)

	_build_uis()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _build_uis() -> void:
	var header := Label.new()
	header.text = "--- DEBUG: Overlays ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	add_child(header)

	var specs: Array[Dictionary] = [
		{text = "Show Body Collider", callback = _apply_body_visible},
		{text = "Show Racket Collider", callback = _apply_racket_visible},
		{text = "Show State Label", callback = _apply_state_label_visible},
		{text = "Show Ground Ray", callback = _apply_ground_ray_visible},
		{text = "Show Soul Bound", callback = _apply_soul_bound_visible},
	]
	for spec in specs:
		var c := CheckBox.new()
		c.text = spec.text
		c.button_pressed = false
		c.focus_mode = Control.FOCUS_NONE
		c.toggled.connect(spec.callback)
		add_child(c)


func _apply_body_visible(pressed: bool) -> void:
	_for_each_paddle("set_body_collider_visible", pressed)


func _apply_racket_visible(pressed: bool) -> void:
	_for_each_paddle("set_racket_collider_visible", pressed)


func _apply_state_label_visible(pressed: bool) -> void:
	_for_each_paddle("set_state_label_visible", pressed)


func _apply_ground_ray_visible(pressed: bool) -> void:
	_for_each_paddle("set_ground_ray_visible", pressed)


func _apply_soul_bound_visible(pressed: bool) -> void:
	for court in get_tree().get_nodes_in_group(&"courts"):
		var draw: Variant = court.get("soul_bound_debug_draw")
		if draw != null and draw.has_method("set_soul_bound_visible"):
			draw.set_soul_bound_visible(pressed)


func _for_each_paddle(method: StringName, value: Variant) -> void:
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_method(method):
			paddle.call(method, value)
