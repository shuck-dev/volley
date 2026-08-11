class_name PaddleAnimationController
extends RefCounted

signal state_changed(state: StringName, speed_scale: float)

const PaddleSwingMathScript: GDScript = preload("res://scripts/core/paddle_swing_math.gd")

## Playback speed used for every non-anticipated animation transition.
const DEFAULT_SPEED_SCALE: float = 1.0
## Contact frame and fps of the 5fps swing animations in resources/animations/sam.tres.
const SWING_CONTACT_FRAME_INDEX: int = 3
const SWING_ANIMATION_BASE_FPS: float = 5.0
## Physical ceiling on swing playback speed; not a designer tunable.
const MAX_SWING_SPEED_SCALE: float = 3.0

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


## Resolves the swing-start state ahead of contact, played at `speed_scale`.
func on_anticipated_hit(grounded: bool, speed_scale: float) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_anticipated_hit(grounded, _vertical_motion, false)

	_emit_if_changed(previous_state, speed_scale)


## Starts the swing early enough for its contact frame to land when the ball reaches `racket_x`.
func on_zone_entered(
	ball_x: float, ball_velocity_x: float, racket_x: float, grounded: bool
) -> void:
	if is_swing_pending():
		return

	var contact_time: float = PaddleSwingMathScript.time_to_contact(
		racket_x, ball_x, ball_velocity_x
	)
	if contact_time < 0.0:
		return

	var speed_scale: float = PaddleSwingMathScript.speed_scale_for_contact_time(
		contact_time, SWING_CONTACT_FRAME_INDEX, SWING_ANIMATION_BASE_FPS, MAX_SWING_SPEED_SCALE
	)

	on_anticipated_hit(grounded, speed_scale)


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
