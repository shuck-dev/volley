class_name PaddleBounceMath
extends RefCounted

## Where a paddle bounce sends the ball: contact placement, paddle spin, then
## clamped to the legal bounce range. Shared by Ball (to apply the bounce) and
## dev overlays (to recompute the same values for visualization without Ball
## reporting anything back).


## Resolved bounce direction and its inputs, so a caller can both apply and display it.
class Result:
	var offset_norm: float
	var target_angle: float
	var incoming_y_sign: float
	var horizontal_sign: float
	var direction: Vector2


## Null when the ball has no horizontal motion to bounce off of (e.g. resting
## dead-centre on a paddle).
static func resolve_bounce(
	ball_velocity: Vector2,
	ball_position: Vector2,
	struck_paddle: Paddle,
	return_angle_max_degrees: float,
	english_coefficient: float,
	bounce_min_angle_degrees: float,
	bounce_max_angle_degrees: float,
) -> Result:
	var horizontal_sign: float = reverse_incoming_direction(ball_velocity)
	if horizontal_sign == 0.0:
		return null

	var offset_norm: float = contact_placement(
		ball_position, struck_paddle, return_angle_max_degrees
	)
	var placement_angle: float = offset_norm * deg_to_rad(return_angle_max_degrees)
	var spin_angle: float = paddle_spin(struck_paddle, english_coefficient)
	var incoming_y_sign: float = signf(ball_velocity.y)

	var steered_angle: float = steer_toward_spin(placement_angle, spin_angle)
	var target_angle: float = clamp_to_legal_bounce_range(
		steered_angle, incoming_y_sign, bounce_min_angle_degrees, bounce_max_angle_degrees
	)

	var result := Result.new()
	result.offset_norm = offset_norm
	result.target_angle = target_angle
	result.incoming_y_sign = incoming_y_sign
	result.horizontal_sign = horizontal_sign
	result.direction = launch_direction(target_angle, horizontal_sign)
	return result


# A bounce always sends the ball back the way it came from, horizontally.
static func reverse_incoming_direction(ball_velocity: Vector2) -> float:
	return -signf(ball_velocity.x)


# Where on the paddle face the ball made contact, -1 (top) to 1 (bottom), scaled
# to zero if the paddle allows no return-angle spread or has no measurable height.
static func contact_placement(
	ball_position: Vector2, struck_paddle: Paddle, return_angle_max_degrees: float
) -> float:
	var half_height: float = struck_paddle.get_half_height()
	if return_angle_max_degrees <= 0.0 or half_height <= 0.0:
		return 0.0

	return clampf((ball_position.y - struck_paddle.global_position.y) / half_height, -1.0, 1.0)


# Spin the paddle imparts by its own motion at the moment of contact.
static func paddle_spin(struck_paddle: Paddle, english_coefficient: float) -> float:
	return struck_paddle.velocity.y * english_coefficient


# A moving paddle steers the bounce fully into its motion hemisphere, so a swing
# never cancels out the contact placement, only adds to or redirects it.
static func steer_toward_spin(placement_angle: float, spin_angle: float) -> float:
	if is_zero_approx(spin_angle):
		return placement_angle

	return (absf(placement_angle) + absf(spin_angle)) * signf(spin_angle)


# Keeps the bounce off dead-horizontal and dead-vertical; a angle with no
# direction of its own (dead centre, no spin) breaks the tie toward the ball's
# incoming vertical direction.
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


static func launch_direction(target_angle: float, horizontal_sign: float) -> Vector2:
	return Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
