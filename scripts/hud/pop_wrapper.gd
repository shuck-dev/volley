extends PanelContainer

var _drag := DraggableBehavior.new()


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		var btn: Control = get_meta(&"dock_btn", null) as Control
		if btn != null:
			btn.position = Vector2(position.x, position.y - 24)
		get_viewport().set_input_as_handled()
