class_name PaddleAnimationController
extends RefCounted

## Diffs state before/after each call rather than connecting to the machine's signal, since a
## stored connection back to this RefCounted would form an uncollectable reference cycle.

signal state_changed(state: StringName)

var _state_machine: PaddleAnimationStateMachine
var _last_y: float = 0.0
var _vertical_motion: float = 0.0


func start(initial_y: float) -> void:
	_last_y = initial_y
	_ensure_state_machine()


## Samples vertical motion since the last tick and resolves the new animation state.
func tick(current_y: float, grounded: bool, crouching: bool) -> void:
	_vertical_motion = current_y - _last_y
	_last_y = current_y
	_ensure_state_machine()
	var previous_state := _state_machine.get_state()
	_state_machine.update(grounded, _vertical_motion, crouching)
	_emit_if_changed(previous_state)


func on_hit(grounded: bool, crouching: bool) -> void:
	_ensure_state_machine()
	var previous_state := _state_machine.get_state()
	_state_machine.on_hit(grounded, _vertical_motion, crouching)
	_emit_if_changed(previous_state)


func on_swing_finished(grounded: bool, crouching: bool) -> void:
	_ensure_state_machine()
	var previous_state := _state_machine.get_state()
	_state_machine.on_swing_finished(grounded, _vertical_motion, crouching)
	_emit_if_changed(previous_state)


func get_state() -> StringName:
	_ensure_state_machine()
	return _state_machine.get_state()


func _emit_if_changed(previous_state: StringName) -> void:
	var new_state := _state_machine.get_state()

	if new_state != previous_state:
		state_changed.emit(new_state)


func _ensure_state_machine() -> void:
	if _state_machine == null:
		_state_machine = load("res://scripts/core/paddle_animation_state_machine.gd").new()
