class_name PaddleAIMath
extends RefCounted

## Pure math functions for paddle AI: ball intercept prediction and noise sampling.


static func predict_intercept(
	ball_position: Vector2,
	ball_velocity: Vector2,
	target_x: float,
) -> float:
	var velocity_x_abs: float = abs(ball_velocity.x)
	if velocity_x_abs < 1.0:
		return ball_position.y

	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	var arena_top: float = -arena_half
	var arena_bottom: float = arena_half

	var time_to_reach: float = abs(target_x - ball_position.x) / velocity_x_abs
	var simulated_y: float = ball_position.y + ball_velocity.y * time_to_reach

	for _step in range(20):
		if simulated_y >= arena_top and simulated_y <= arena_bottom:
			break
		if simulated_y < arena_top:
			simulated_y = arena_top + (arena_top - simulated_y)
		elif simulated_y > arena_bottom:
			simulated_y = arena_bottom - (simulated_y - arena_bottom)

	return clampf(simulated_y, arena_top, arena_bottom)


static func random_offset(noise_range: float) -> float:
	if noise_range <= 0.0:
		return 0.0
	# Box-Muller: normal distribution clamped at 2 sigma
	var u1: float = randf_range(0.001, 1.0)
	var u2: float = randf_range(0.0, 1.0)
	var normal: float = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return clampf(normal * noise_range, -noise_range * 2.0, noise_range * 2.0)
