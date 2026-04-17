class_name DraggableBehavior
extends RefCounted

## Mixin: call `try_start(control, event)` from `_gui_input` to begin a drag,
## and `update(control, event)` from `_input` so motion and release track the
## cursor even when it outruns the control's bounds.

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func try_start(control: Control, event: InputEvent) -> bool:
	if _dragging:
		return false
	if not (event is InputEventMouseButton):
		return false
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return false
	_dragging = true
	_drag_offset = control.position - control.get_global_mouse_position()
	return true


func update(control: Control, event: InputEvent) -> bool:
	if not _dragging:
		return false
	if event is InputEventMouseMotion:
		control.position = control.get_global_mouse_position() + _drag_offset
		return true
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_dragging = false
			return true
	return false
