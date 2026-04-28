class_name CursorState
extends RefCounted

## SH-297: cursor state vocabulary for the grab gesture.
##
## The drag controller derives one of these per physics frame from the gesture-in-flight
## flag plus the current `can_accept` poll result at the held position. The cursor overlay
## (and any future software-cursor texture set, SH-298) is a pure visual layer driven off
## this state. The state machine is the contract; visuals are replaceable.

enum State {
	## No gesture in flight.
	DEFAULT,
	## Gesture in flight, no target accepts at the held position.
	DRAGGING,
	## Gesture in flight, a target accepts at the held position.
	CAN_DROP,
	## Gesture in flight, the position is invalid (over a wall, obstacle, off-venue).
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
