class_name PaddleBounceMath
extends RefCounted

## Pure math for paddle-bounce return angle: offset, english, and angle clamping.
## Shared by Ball (to apply the bounce) and dev overlays (to recompute the same
## values for visualization without Ball reporting anything back).


## Resolved bounce direction and its inputs, so a caller can both apply and display it.
class Result:
	var offset_norm: float
	var target_angle: float
	var incoming_y_sign: float
	var horizontal_sign: float
	var direction: Vector2


## Where on the paddle the ball struck drives the return angle. Null when the ball
## has no horizontal motion to bounce off of (e.g. resting dead-centre on a paddle).
static func resolve_bounce(
	ball_velocity: Vector2,
	ball_position: Vector2,
	struck_paddle: Paddle,
	return_angle_max_degrees: float,
	english_coefficient: float,
	bounce_min_angle_degrees: float,
	bounce_max_angle_degrees: float,
) -> Result:
	var horizontal_sign: float = _return_horizontal_sign(ball_velocity)
	if horizontal_sign == 0.0:
		return null

	var offset_norm: float = _contact_offset_norm(
		ball_position, struck_paddle, return_angle_max_degrees
	)
	var offset_angle: float = offset_norm * deg_to_rad(return_angle_max_degrees)
	var english_angle: float = _english_angle(struck_paddle, english_coefficient)
	var incoming_y_sign: float = signf(ball_velocity.y)

	var blended_angle: float = _blend_english_into_offset(offset_angle, english_angle)
	var target_angle: float = _clamp_off_horizontal_and_vertical(
		blended_angle, incoming_y_sign, bounce_min_angle_degrees, bounce_max_angle_degrees
	)

	var result := Result.new()
	result.offset_norm = offset_norm
	result.target_angle = target_angle
	result.incoming_y_sign = incoming_y_sign
	result.horizontal_sign = horizontal_sign
	result.direction = _direction_from_angle(target_angle, horizontal_sign)
	return result


# Bounce always reverses the ball's incoming horizontal direction. Zero when the
# ball has no horizontal velocity to reverse (straight vertical drop onto a paddle).
static func _return_horizontal_sign(ball_velocity: Vector2) -> float:
	return -signf(ball_velocity.x)


# Normalized contact point on the paddle face, -1 (top) to 1 (bottom). Zero when
# there's no return-angle spread to place the contact within, or no paddle height
# to measure it against.
static func _contact_offset_norm(
	ball_position: Vector2, struck_paddle: Paddle, return_angle_max_degrees: float
) -> float:
	var half_height: float = struck_paddle.get_half_height()
	if return_angle_max_degrees <= 0.0 or half_height <= 0.0:
		return 0.0

	return clampf((ball_position.y - struck_paddle.global_position.y) / half_height, -1.0, 1.0)


# English: spin imparted by the paddle's own motion at the moment of contact.
static func _english_angle(struck_paddle: Paddle, english_coefficient: float) -> float:
	return struck_paddle.velocity.y * english_coefficient


# Moving paddle forces the bounce into its motion hemisphere so the english never cancels offset.
static func _blend_english_into_offset(offset_angle: float, english_angle: float) -> float:
	if is_zero_approx(english_angle):
		return offset_angle

	return (absf(offset_angle) + absf(english_angle)) * signf(english_angle)


# Clamps magnitude off horizontal/vertical; on zero angle the incoming y-sign breaks the tie.
static func _clamp_off_horizontal_and_vertical(
	angle: float, incoming_y_sign: float, min_degrees: float, max_degrees: float
) -> float:
	var min_magnitude: float = deg_to_rad(min_degrees)
	var max_magnitude: float = deg_to_rad(max_degrees)
	var sign_y: float = signf(angle)

	if sign_y == 0.0:
		sign_y = incoming_y_sign

	if sign_y == 0.0:
		sign_y = 1.0

	var magnitude: float = clampf(absf(angle), min_magnitude, max_magnitude)
	return sign_y * magnitude


static func _direction_from_angle(target_angle: float, horizontal_sign: float) -> Vector2:
	return Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
