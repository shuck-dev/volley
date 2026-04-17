class_name DraggableBehavior
extends RefCounted

## Mixin helper: call `process(control, event)` from a Control's `_gui_input`.
## Returns true when the event was consumed for dragging.

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
