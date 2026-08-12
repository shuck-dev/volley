class_name PaddleAnimationController
extends RefCounted

signal state_changed(state: StringName)

const PaddleSwingMathScript: GDScript = preload("res://scripts/core/paddle_swing_math.gd")

## Per-swing-animation contact timing, from resources/animations/sam.tres. `contact_frames` is
## how many frame-durations (at `base_fps`) elapse before the contact moment: for a multi-frame
## swing that's its contact frame's index (time to reach it); for swing_grounded_low, whose single
## frame IS the contact frame from the first tick, it's 1 (that frame's own duration), so the
## frame stretches to hold until contact instead of computing a zero-length wait.
const SWING_TIMING_BY_STATE: Dictionary[StringName, Dictionary] = {
	&"swing_flying": {"contact_frames": 3, "base_fps": 5.0},
	&"swing_grounded": {"contact_frames": 2, "base_fps": 5.0},
	&"swing_grounded_low": {"contact_frames": 1, "base_fps": 2.0},
}

## Physical ceiling on swing playback speed; not a designer tunable.
const MAX_SWING_SPEED_SCALE: float = 3.0

var _state_machine: PaddleAnimationStateMachine
var _last_y: float = 0.0
var _vertical_motion: float = 0.0


func _init(initial_y: float) -> void:
	_last_y = initial_y
	_state_machine = PaddleAnimationStateMachine.new()
	_state_machine.state_changed.connect(state_changed.emit)


## Samples vertical motion since the last tick and resolves the new animation state.
func tick(current_y: float, grounded: bool, crouching: bool) -> void:
	_vertical_motion = current_y - _last_y
	_last_y = current_y

	_state_machine.update(grounded, _vertical_motion, crouching)


## Resolves the swing-start state, on contact or ahead of it; caller sets sprite.speed_scale first
## for an anticipated swing.
func start_swing(grounded: bool, crouching: bool = false) -> void:
	_state_machine.start_swing(grounded, _vertical_motion, crouching)


## Playback speed so the swing's contact frame lands when the ball reaches `racket_position`, or
## -1.0 if a swing is already pending or the ball's contact time can't be determined.
func compute_zone_entry_speed_scale(
	ball_position: Vector2,
	ball_velocity: Vector2,
	racket_position: Vector2,
	grounded: bool,
	crouching: bool = false,
) -> float:
	if is_swing_pending():
		return -1.0

	var contact_time: float = PaddleSwingMathScript.time_to_contact(
		racket_position, ball_position, ball_velocity
	)
	if contact_time < 0.0:
		return -1.0

	var swing_state: StringName = PaddleAnimationStateMachine.resolve_swing_state(
		grounded, crouching
	)
	var timing: Dictionary = SWING_TIMING_BY_STATE[swing_state]

	return PaddleSwingMathScript.speed_scale_for_contact_time(
		contact_time, timing["contact_frames"], timing["base_fps"], MAX_SWING_SPEED_SCALE
	)


## Resolves the post-swing state once the swing animation completes.
func finish_swing(grounded: bool, crouching: bool) -> void:
	_state_machine.finish_swing(grounded, _vertical_motion, crouching)


func get_state() -> StringName:
	return _state_machine.get_state()


func is_swing_pending() -> bool:
	return _state_machine.is_swing_pending()
