class_name DevOverlayPanel
extends VBoxContainer


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 2)

	_add_label("--- DEBUG: Overlays ---", Color(1.0, 1.0, 0.6))

	_add_checkbox("Show Body Collider", _apply_body_visible)
	_add_checkbox("Show Racket Collider", _apply_racket_visible)
	_add_checkbox("Show State Label", _apply_state_label_visible)
	_add_checkbox("Show Ground Ray", _apply_ground_ray_visible)
	_add_checkbox("Show Soul Bound", _apply_soul_bound_visible)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))


func _add_label(text: String, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", colour)
	add_child(label)


func _add_checkbox(text: String, apply: Callable) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.button_pressed = false
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(apply)
	add_child(checkbox)


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
