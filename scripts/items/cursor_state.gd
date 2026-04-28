class_name CursorState
extends RefCounted

enum State {
	DEFAULT,
	DRAGGING,
	CAN_DROP,
	FORBIDDEN,
}


static func to_string_name(state: int) -> StringName:
	match state:
		State.DEFAULT:
			return &"default"
		State.DRAGGING:
			return &"dragging"
		State.CAN_DROP:
			return &"can_drop"
		State.FORBIDDEN:
			return &"forbidden"
		_:
			return &"default"
