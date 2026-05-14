class_name BallEffectProcessor
extends Node

## Debug-only signal: fired after every paddle bounce, post-clamp and post-english, so dev overlays can echo the resolved direction.
signal bounce_resolved(
	struck_paddle: Paddle,
	offset_norm: float,
	target_angle: float,
	incoming_y_sign: float,
	horizontal_sign: float
)

var ball: Ball
var paddles: Array[Node2D] = []
var item_manager: Node

var _base_speed := 0.0
var _applied_offset := 0.0


func _ready() -> void:
	if item_manager == null:
		item_manager = ItemManager


func process_frame(delta: float) -> void:
	_apply_magnetism(delta)
	_sync_speed_limits()


func sync_base_speed() -> void:
	_base_speed = ball.speed - _applied_offset


func _sync_speed_limits() -> void:
	_sync_min_speed()
	_sync_max_speed()
	_apply_speed_offset()


func _sync_min_speed() -> void:
	var new_min: float = Stats.resolve(
		GameRules.base.ball_speed_min, &"ball_speed_min", item_manager
	)
	if not is_equal_approx(new_min, ball.min_speed):
		_base_speed += new_min - ball.min_speed
		ball.min_speed = new_min


func _sync_max_speed() -> void:
	ball.max_speed = (
		ball.min_speed
		+ Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", item_manager)
	)
	ball.speed_increment = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", item_manager
	)


func _apply_speed_offset() -> void:
	_applied_offset = Stats.resolve(
		GameRules.base.ball_speed_offset, &"ball_speed_offset", item_manager
	)
	ball.speed = clampf(_base_speed + _applied_offset, ball.min_speed, ball.max_speed)


func process_hit(struck_paddle: Paddle) -> void:
	_apply_paddle_offset_return(struck_paddle)


func _apply_magnetism(delta: float) -> void:
	var magnetism: float = Stats.resolve(
		GameRules.base.ball_magnetism, &"ball_magnetism", item_manager
	)
	if magnetism <= 0.0 or paddles.is_empty():
		return

	var closest_paddle: Node2D = null
	var closest_distance := INF
	for paddle in paddles:
		if not is_instance_valid(paddle):
			continue
		var distance: float = ball.global_position.distance_to(paddle.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_paddle = paddle

	if closest_paddle == null:
		return

	var pull_direction: Vector2 = (
		(closest_paddle.global_position - ball.global_position).normalized()
	)
	var pull_strength: float = magnetism * delta
	var new_direction: Vector2 = (
		(ball.linear_velocity.normalized() + pull_direction * pull_strength).normalized()
	)
	ball.linear_velocity = new_direction * ball.speed


# Where on the paddle the ball struck drives the return angle; centre returns flat, edges steepen.
func _apply_paddle_offset_return(struck_paddle: Paddle) -> void:
	var max_degrees: float = (
		Stats
		. resolve(
			GameRules.paddle.paddle_return_angle_max_degrees,
			&"paddle_return_angle_max_degrees",
			item_manager,
		)
	)
	if max_degrees <= 0.0:
		return
	if struck_paddle == null:
		return

	var half_height: float = struck_paddle.get_half_height()
	if half_height <= 0.0:
		return

	var horizontal_sign: float = signf(ball.linear_velocity.x)
	if horizontal_sign == 0.0:
		return

	var offset_norm: float = clampf(
		(ball.global_position.y - struck_paddle.global_position.y) / half_height, -1.0, 1.0
	)
	var offset_angle: float = offset_norm * deg_to_rad(max_degrees)
	var english_coefficient: float = Stats.resolve(
		GameRules.paddle.paddle_english_coefficient, &"paddle_english_coefficient", item_manager
	)
	var english_angle: float = struck_paddle.velocity.y * english_coefficient
	var incoming_y_sign: float = signf(ball.linear_velocity.y)
	# Moving paddle forces the bounce into its motion hemisphere so the english never cancels offset.
	var blended_angle: float
	if not is_zero_approx(english_angle):
		blended_angle = (absf(offset_angle) + absf(english_angle)) * signf(english_angle)
	else:
		blended_angle = offset_angle
	var target_angle: float = _clamp_off_horizontal_and_vertical(blended_angle, incoming_y_sign)
	var direction := Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
	ball.linear_velocity = direction * ball.speed
	bounce_resolved.emit(struck_paddle, offset_norm, target_angle, incoming_y_sign, horizontal_sign)


# Clamps magnitude off horizontal/vertical; on zero angle the incoming y-sign breaks the tie.
func _clamp_off_horizontal_and_vertical(angle: float, incoming_y_sign: float) -> float:
	var min_degrees: float = (
		Stats
		. resolve(
			GameRules.paddle.paddle_bounce_min_angle_degrees,
			&"paddle_bounce_min_angle_degrees",
			item_manager,
		)
	)
	var max_degrees: float = (
		Stats
		. resolve(
			GameRules.paddle.paddle_bounce_max_angle_degrees,
			&"paddle_bounce_max_angle_degrees",
			item_manager,
		)
	)
	var min_magnitude: float = deg_to_rad(min_degrees)
	var max_magnitude: float = deg_to_rad(max_degrees)
	var sign_y: float = signf(angle)
	if sign_y == 0.0:
		sign_y = incoming_y_sign
	if sign_y == 0.0:
		sign_y = 1.0
	var magnitude: float = clampf(absf(angle), min_magnitude, max_magnitude)
	return sign_y * magnitude
