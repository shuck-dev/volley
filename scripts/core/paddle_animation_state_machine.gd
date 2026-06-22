class_name PaddleAnimationStateMachine
extends RefCounted

## Stateful machine for swing lifecycle and animation state transitions.

signal state_changed(state: StringName)

var _current_state: StringName = &""
var _swing_pending: bool = false


## Updates the state based on grounded, vertical motion, crouching, and internal swing_pending.
## Emits state_changed only if the state actually changed.
func update(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
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


## Clears swing pending and recomputes the state.
## Caller must supply grounded and vertical_motion to keep the state in sync.
func on_swing_finished(grounded: bool, vertical_motion: float) -> void:
	_swing_pending = false
	update(grounded, vertical_motion)


func get_state() -> StringName:
	return _current_state


static func _resolve_state(
	grounded: bool, vertical_motion: float, swing_pending: bool, crouching: bool = false
) -> StringName:
	if swing_pending:
		if grounded:
			return &"low_swing_grounded" if crouching else &"swing_grounded"
		return &"swing_flying"

	if grounded:
		return &"ready_grounded_crouch" if crouching else &"ready_grounded"

	if not is_zero_approx(vertical_motion):
		return &"flying_up" if vertical_motion < 0.0 else &"flying_down"

	return &"ready_flying"
