class_name PaddleAnimationController
extends RefCounted

signal state_changed(state: StringName)

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

	_emit_if_changed(previous_state)


## Resolves the swing-start state on a successful hit.
func on_hit(grounded: bool, crouching: bool) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_hit(grounded, _vertical_motion, crouching)

	_emit_if_changed(previous_state)


## Resolves the post-swing state once the swing animation completes.
func on_swing_finished(grounded: bool, crouching: bool) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_swing_finished(grounded, _vertical_motion, crouching)

	_emit_if_changed(previous_state)


func get_state() -> StringName:
	return _state_machine.get_state()


func _emit_if_changed(previous_state: StringName) -> void:
	var new_state := _state_machine.get_state()

	if new_state != previous_state:
		state_changed.emit(new_state)
