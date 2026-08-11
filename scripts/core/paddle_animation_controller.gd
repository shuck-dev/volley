class_name PaddleAnimationController
extends RefCounted

signal state_changed(state: StringName)

var _state_machine: PaddleAnimationStateMachine
var _last_y: float = 0.0
var _vertical_motion: float = 0.0
var _anticipated_ball: Ball


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


## Starts the swing early enough for its contact frame to land on the closest approaching ball.
## Anticipation never reads live crouch input; the real on_hit swing corrects for crouch at contact.
func tick_anticipation(
	reconciler: BallReconciler, paddle_x: float, lane_sign: float, grounded: bool
) -> void:
	if reconciler == null:
		return

	var candidate: Ball = reconciler.get_closest_approaching_ball(paddle_x, lane_sign)

	# A ball stops qualifying (hit, left play, reversed) once it no longer ranks as closest-approaching.
	if candidate != _anticipated_ball:
		_anticipated_ball = null

	if candidate == null or candidate == _anticipated_ball:
		return

	if _state_machine.is_swing_pending():
		return

	var speed_x: float = absf(candidate.linear_velocity.x)
	if speed_x < 1.0:
		return

	var time_to_contact: float = absf(paddle_x - candidate.position.x) / speed_x

	if time_to_contact > GameRules.paddle.swing_anticipation_lead_time_seconds:
		return

	_anticipated_ball = candidate
	on_anticipated_hit(grounded)


## Resolves the swing-start state on a successful hit.
func on_hit(grounded: bool, crouching: bool) -> void:
	_anticipated_ball = null

	var previous_state := _state_machine.get_state()
	_state_machine.on_hit(grounded, _vertical_motion, crouching)

	_emit_if_changed(previous_state)


## Resolves the swing-start state ahead of contact, so the swing's contact frame lands on time.
func on_anticipated_hit(grounded: bool) -> void:
	var previous_state := _state_machine.get_state()
	_state_machine.on_anticipated_hit(grounded, _vertical_motion, false)

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
