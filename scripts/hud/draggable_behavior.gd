class_name DraggableBehavior
extends RefCounted

## Mixin: call `process(control, event)` in `_gui_input`; returns true when consumed.

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func process(control: Control, event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return false
		if mouse_button.pressed:
			_dragging = true
			_drag_offset = control.position - control.get_global_mouse_position()
			return true
		_dragging = false
		return false
	if event is InputEventMouseMotion and _dragging:
		control.position = control.get_global_mouse_position() + _drag_offset
		return true
	return false
