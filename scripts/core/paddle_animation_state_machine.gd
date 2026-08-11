class_name PaddleAnimationStateMachine
extends RefCounted

## Stateful machine for swing lifecycle and animation state transitions.

signal state_changed(state: StringName)

var _current_state: StringName = &""
var _swing_pending: bool = false


## Updates the animation state. A flying swing completes uninterrupted on landing; a grounded
## swing cancels if the paddle leaves the ground mid-swing.
func update(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	if _swing_pending and _current_state == &"swing_flying":
		return

	if (
		_swing_pending
		and not grounded
		and _current_state in [&"swing_grounded", &"swing_grounded_low"]
	):
		_swing_pending = false

	var new_state: StringName = _resolve_state(grounded, vertical_motion, _swing_pending, crouching)

	if new_state == _current_state:
		return

	_current_state = new_state
	state_changed.emit(_current_state)


## Sets swing pending true and recomputes the state.
## Caller must supply grounded and vertical_motion to keep the state in sync.
func on_hit(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	_swing_pending = true
	update(grounded, vertical_motion, crouching)


## Starts the swing early so its contact frame lands on the ball's actual arrival.
## Caller must supply grounded and vertical_motion to keep the state in sync.
func on_anticipated_hit(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	_swing_pending = true
	update(grounded, vertical_motion, crouching)


## Clears swing pending and recomputes the state.
## Caller must supply grounded and vertical_motion to keep the state in sync.
func on_swing_finished(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	_swing_pending = false
	update(grounded, vertical_motion, crouching)


func get_state() -> StringName:
	return _current_state


func is_swing_pending() -> bool:
	return _swing_pending


static func _resolve_state(
	grounded: bool, vertical_motion: float, swing_pending: bool, crouching: bool = false
) -> StringName:
	if swing_pending:
		if grounded:
			return &"swing_grounded_low" if crouching else &"swing_grounded"
		return &"swing_flying"

	if grounded:
		return &"ready_grounded_low" if crouching else &"ready_grounded"

	if not is_zero_approx(vertical_motion):
		return &"flying_up" if vertical_motion < 0.0 else &"flying_down"

	return &"ready_flying"
