class_name DevBouncePanel
extends VBoxContainer

## Checkboxes toggling other dev overlays (bounce cone, soul bound, arc travel, ball names).

var _drag := DraggableBehavior.new()


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 2)
	_build_checks()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


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
