class_name PaddleBounceMath
extends RefCounted

const BOUNCE_MIN_ANGLE_DEGREES := 3.0
const BOUNCE_MAX_ANGLE_DEGREES := 87.0


## Returns the direction a bounce sends the ball in, or null if it has no horizontal motion to bounce off of.
static func bounce_direction(
	ball_velocity: Vector2,
	ball_position: Vector2,
	paddle_position: Vector2,
	paddle_half_height: float,
	return_angle_max_degrees: float,
) -> Variant:
	var horizontal_sign: float = reverse_incoming_direction(ball_velocity)
	if horizontal_sign == 0.0:
		return null

	var placement_angle: float = (
		contact_placement(
			ball_position, paddle_position, paddle_half_height, return_angle_max_degrees
		)
		* deg_to_rad(return_angle_max_degrees)
	)
	var target_angle: float = clamp_to_legal_bounce_range(
		placement_angle,
		signf(ball_velocity.y),
		BOUNCE_MIN_ANGLE_DEGREES,
		BOUNCE_MAX_ANGLE_DEGREES,
	)

	return launch_direction(target_angle, horizontal_sign)


## Returns the horizontal direction a bounce should send the ball in, opposite its incoming direction.
static func reverse_incoming_direction(ball_velocity: Vector2) -> float:
	return -signf(ball_velocity.x)


## Returns where the ball made contact on the paddle face, -1 (top) to 1 (bottom).
static func contact_placement(
	ball_position: Vector2,
	paddle_position: Vector2,
	paddle_half_height: float,
	return_angle_max_degrees: float,
) -> float:
	if return_angle_max_degrees <= 0.0 or paddle_half_height <= 0.0:
		return 0.0

	return clampf((ball_position.y - paddle_position.y) / paddle_half_height, -1.0, 1.0)


## Returns the angle clamped off dead-horizontal and dead-vertical, breaking a
## zero-magnitude tie toward the ball's incoming vertical direction.
static func clamp_to_legal_bounce_range(
	angle: float, incoming_y_sign: float, min_degrees: float, max_degrees: float
) -> float:
	var floor_angle: float = deg_to_rad(min_degrees)
	var ceiling_angle: float = deg_to_rad(max_degrees)
	var direction_sign: float = signf(angle)

	if direction_sign == 0.0:
		direction_sign = incoming_y_sign

	if direction_sign == 0.0:
		direction_sign = 1.0

	var magnitude: float = clampf(absf(angle), floor_angle, ceiling_angle)
	return direction_sign * magnitude


## Returns the unit direction vector for a bounce at the given angle and horizontal sign.
static func launch_direction(target_angle: float, horizontal_sign: float) -> Vector2:
	return Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
