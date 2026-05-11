class_name PaddleAIMath
extends RefCounted

## Pure math functions for paddle AI: ball intercept prediction and noise sampling.


## Predicts where the ball will cross target_x under PLAY-ARC parabolic physics.
## Above bound_y (smaller y), gravity acts on vy; below, constant velocity.
## Returns the y-position of the intercept, clamped to the arena range.
static func predict_intercept(
	ball_position: Vector2,
	ball_velocity: Vector2,
	target_x: float,
	bound_y: float,
	gravity: float,
) -> float:
	var horizontal_speed: float = abs(ball_velocity.x)
	if horizontal_speed < 1.0:
		return ball_position.y

	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	var time_to_reach: float = abs(target_x - ball_position.x) / horizontal_speed
	var intercept_y: float = _simulate_intercept_y(
		ball_position.y, ball_velocity.y, bound_y, gravity, time_to_reach
	)
	return clampf(intercept_y, -arena_half, arena_half)


static func _simulate_intercept_y(
	start_y: float,
	start_vertical_velocity: float,
	bound_y: float,
	gravity: float,
	time_to_reach: float,
) -> float:
	var step_count: int = 32
	var step_seconds: float = time_to_reach / float(step_count)
	var current_y: float = start_y
	var vertical_velocity: float = start_vertical_velocity

	for _step in range(step_count):
		if current_y < bound_y:
			vertical_velocity += gravity * step_seconds
		current_y += vertical_velocity * step_seconds

	return current_y


## Returns a random offset in pixels from a normal distribution,
## clamped to twice noise_range. Returns 0 if noise_range is zero.
static func random_offset(noise_range: float) -> float:
	if noise_range <= 0.0:
		return 0.0
	# Box-Muller: normal distribution clamped at 2 sigma
	var u1: float = randf_range(0.001, 1.0)
	var u2: float = randf_range(0.0, 1.0)
	var normal: float = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return clampf(normal * noise_range, -noise_range * 2.0, noise_range * 2.0)
