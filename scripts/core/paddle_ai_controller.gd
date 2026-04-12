class_name PaddleAIController
extends Node

## Abstract base for paddle AI controllers. Owns the shared prediction,
## reaction delay, noise, tracking, and drift algorithm. Subclasses override
## _ball_approaching() and _get_paddle_speed() to specialise behaviour.

@export var paddle: CharacterBody2D
@export var ball: RigidBody2D
@export var config: PaddleAIConfig

var _enabled := false

# --- reaction delay ---
var _position_buffer: Array
var _position_buffer_index := 0

# --- noise ---
var _noise_offset := 0.0
var _last_ball_direction_x := 0.0


func _ready() -> void:
	_position_buffer.resize(config.reaction_delay_frames)
	_position_buffer.fill(0.0)


func _physics_process(_delta: float) -> void:
	if not _enabled:
		return
	if _ball_approaching():
		_track()
	else:
		_drift_to_center()


func set_enabled(value: bool) -> void:
	_enabled = value


## Override: which ball x-direction counts as "coming toward me."
func _ball_approaching() -> bool:
	assert(false, "PaddleAIController._ball_approaching() is abstract")
	return false


## Override: the paddle's movement speed ceiling.
func _get_paddle_speed() -> float:
	assert(false, "PaddleAIController._get_paddle_speed() is abstract")
	return 0.0


## Override point for subclasses that need a different prediction strategy.
func _predict_intercept() -> float:
	var ball_position: Vector2 = ball.position
	var ball_velocity: Vector2 = ball.linear_velocity
	var target_x: float = paddle.position.x

	var velocity_x_abs: float = abs(ball_velocity.x)
	if velocity_x_abs < 1.0:
		return ball_position.y

	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	var arena_top: float = -arena_half
	var arena_bottom: float = arena_half

	var time_to_reach: float = abs(target_x - ball_position.x) / velocity_x_abs
	var simulated_y: float = ball_position.y + ball_velocity.y * time_to_reach

	# Reflect off walls until within bounds
	for _step in range(20):
		if simulated_y >= arena_top and simulated_y <= arena_bottom:
			break
		if simulated_y < arena_top:
			simulated_y = arena_top + (arena_top - simulated_y)
		elif simulated_y > arena_bottom:
			simulated_y = arena_bottom - (simulated_y - arena_bottom)

	return clampf(simulated_y, arena_top, arena_bottom)


## Override point for subclasses that need a different noise distribution.
func _sample_noise() -> float:
	if config.noise <= 0.0:
		return 0.0
	# Box-Muller transform for normal distribution
	var u1: float = randf_range(0.001, 1.0)
	var u2: float = randf_range(0.0, 1.0)
	var normal: float = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return normal * config.noise


func _track() -> void:
	_maybe_resample_noise()

	var predicted_intercept_y: float = _predict_intercept()
	var noisy_target: float = predicted_intercept_y + _noise_offset

	var delayed_target: float = _apply_reaction_delay(noisy_target)
	var difference: float = delayed_target - paddle.position.y
	var max_speed: float = _get_paddle_speed() * config.speed_scale

	var target_velocity: float
	if abs(difference) < config.snap_threshold:
		target_velocity = 0.0
	else:
		target_velocity = sign(difference) * max_speed

	var smoothed_velocity: float = lerpf(
		paddle.velocity.y, target_velocity, config.velocity_smoothing
	)
	paddle.drive(smoothed_velocity)


func _drift_to_center() -> void:
	var center_difference: float = -paddle.position.y
	var drift_speed: float = _get_paddle_speed() * config.speed_scale * config.center_drift_scale
	var drift_velocity: float = clampf(center_difference, -drift_speed, drift_speed)
	var smoothed_velocity: float = lerpf(
		paddle.velocity.y, drift_velocity, config.center_drift_smoothing
	)
	paddle.drive(smoothed_velocity)


func _apply_reaction_delay(target_y: float) -> float:
	var delayed: float = _position_buffer[_position_buffer_index]
	_position_buffer[_position_buffer_index] = target_y
	_position_buffer_index = ((_position_buffer_index + 1) % config.reaction_delay_frames)
	return delayed


## Noise is sampled once per ball flight (when ball changes x-direction),
## not every frame. This makes the AI commit to a slightly wrong position.
func _maybe_resample_noise() -> void:
	var current_direction_x: float = ball.linear_velocity.x
	if sign(current_direction_x) != sign(_last_ball_direction_x):
		_noise_offset = _sample_noise()
	_last_ball_direction_x = current_direction_x
