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
	var velocity_x_abs: float = abs(ball_velocity.x)
	if velocity_x_abs < 1.0:
		return ball_position.y

	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	var time_to_reach: float = abs(target_x - ball_position.x) / velocity_x_abs

	var sim_y: float = ball_position.y
	var sim_vy: float = ball_velocity.y
	var step_count: int = 32
	var dt: float = time_to_reach / float(step_count)
	for _step in range(step_count):
		if sim_y < bound_y:
			sim_vy += gravity * dt
		sim_y += sim_vy * dt

	return clampf(sim_y, -arena_half, arena_half)


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
