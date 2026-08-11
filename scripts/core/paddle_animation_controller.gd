class_name PaddleAnimationController
extends RefCounted

signal state_changed(state: StringName, speed_scale: float)

## Playback speed used for every non-anticipated animation transition.
const DEFAULT_SPEED_SCALE: float = 1.0

var _state_machine: PaddleAnimationStateMachine
var _last_y: float = 0.0
var _vertical_motion: float = 0.0


func _init(initial_y: float) -> void:
	_last_y = initial_y
	_state_machine = PaddleAnimationStateMachine.new()


## Samples vertical motion since the last tick and resolves the new animation state.
func tick(current_y: float, grounded: bool, crouching: bool) -> void:
	_vertical_motion = current_y - _last_y
	_last_y = current_y

	var previous_state := _state_machine.get_state()
	_state_machine.update(grounded, _vertical_motion, crouching)

	_emit_if_changed(previous_state, DEFAULT_SPEED_SCALE)


## Resolves the swing-start state on a successful hit.
func on_hit(grounded: bool, crouching: bool) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_hit(grounded, _vertical_motion, crouching)

	_emit_if_changed(previous_state, DEFAULT_SPEED_SCALE)


## Resolves the swing-start state ahead of contact, playing the swing at `speed_scale` so its
## contact frame lands on the ball's actual arrival.
## Anticipation never reads live crouch input; the real on_hit swing corrects for crouch at contact.
func on_anticipated_hit(grounded: bool, speed_scale: float) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_anticipated_hit(grounded, _vertical_motion, false)

	_emit_if_changed(previous_state, speed_scale)


## Resolves the post-swing state once the swing animation completes.
func on_swing_finished(grounded: bool, crouching: bool) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_swing_finished(grounded, _vertical_motion, crouching)

	_emit_if_changed(previous_state, DEFAULT_SPEED_SCALE)


func get_state() -> StringName:
	return _state_machine.get_state()


func is_swing_pending() -> bool:
	return _state_machine.is_swing_pending()


func _emit_if_changed(previous_state: StringName, speed_scale: float) -> void:
	var new_state := _state_machine.get_state()

	if new_state != previous_state:
		state_changed.emit(new_state, speed_scale)
