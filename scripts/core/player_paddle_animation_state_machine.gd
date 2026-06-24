class_name PlayerPaddleAnimationStateMachine
extends PaddleAnimationStateMachine


func update(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	var new_state: StringName = _player_resolve_state(grounded, vertical_motion, crouching)

	if new_state == _current_state:
		return

	_current_state = new_state
	state_changed.emit(_current_state)


func _player_resolve_state(grounded: bool, vertical_motion: float, crouching: bool) -> StringName:
	if _swing_pending:
		if grounded:
			return &"low_swing_grounded" if crouching else &"swing_grounded"
		return &"swing_flying"

	if grounded:
		return &"ready_grounded_low" if crouching else &"ready_grounded"

	return PaddleAnimationStateMachine._resolve_state(grounded, vertical_motion, false)


func on_swing_finished(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	_swing_pending = false
	update(grounded, vertical_motion, crouching)


func on_hit(grounded: bool, vertical_motion: float, crouching: bool = false) -> void:
	_swing_pending = true
	update(grounded, vertical_motion, crouching)
