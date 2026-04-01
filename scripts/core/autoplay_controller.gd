class_name AutoplayController
extends Node

signal autoplay_toggled(autoplay: bool)

@export var paddle: CharacterBody2D
@export var ball: RigidBody2D
@export var config: AutoPlayConfig

var _autoplay: bool
var _position_buffer: Array
var _position_buffer_index := 0


func _ready() -> void:
	_position_buffer.resize(config.reaction_delay_frames)
	_position_buffer.fill(0.0)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_autoplay"):
		toggle()
	if _autoplay:
		_calculate_movement()


func toggle() -> void:
	_autoplay = !_autoplay
	paddle.set_physics_process(!_autoplay)
	autoplay_toggled.emit(_autoplay)


func _calculate_movement() -> void:
	if ball.linear_velocity.x >= 0.0:
		var center_diff: float = -paddle.position.y
		var drift_speed: float = (
			paddle.get_speed() * config.autoplay_speed_scale * config.center_drift_scale
		)
		# clampf: treats distance as velocity directly, capping so the paddle can't overshoot center
		var drift_velocity: float = clampf(center_diff, -drift_speed, drift_speed)
		# lerpf: smooths velocity changes to avoid snapping when switching between drift and tracking
		paddle.drive(lerpf(paddle.velocity.y, drift_velocity, config.center_drift_smoothing))
		return

	# Buffer ball position — always advance so history stays current
	var delayed_y: float = _position_buffer[_position_buffer_index]
	_position_buffer[_position_buffer_index] = ball.position.y
	_position_buffer_index = (_position_buffer_index + 1) % config.reaction_delay_frames

	var diff: float = delayed_y - paddle.position.y
	var max_speed: float = paddle.get_speed() * config.autoplay_speed_scale
	var target_velocity: float = (
		0.0 if abs(diff) < config.snap_threshold else sign(diff) * max_speed
	)
	# lerpf: smooths velocity changes each frame to prevent jitter from abrupt target jumps
	paddle.drive(lerpf(paddle.velocity.y, target_velocity, config.center_drift_smoothing))
