class_name BallEffectProcessor
extends Node

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
	var new_min: float = item_manager.get_stat(&"ball_speed_min")
	if not is_equal_approx(new_min, ball.min_speed):
		_base_speed += new_min - ball.min_speed
		ball.min_speed = new_min
	ball.max_speed = ball.min_speed + item_manager.get_stat(&"ball_speed_max_range")
	ball.speed_increment = item_manager.get_stat(&"ball_speed_increment")

	_applied_offset = item_manager.get_stat(&"ball_speed_offset")
	ball.speed = clampf(_base_speed + _applied_offset, ball.min_speed, ball.max_speed)


func process_hit(struck_paddle: Paddle) -> void:
	_apply_paddle_offset_return(struck_paddle)


func _apply_magnetism(delta: float) -> void:
	var magnetism: float = item_manager.get_stat(&"ball_magnetism")
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
	var max_degrees: float = item_manager.get_stat(&"paddle_return_angle_max_degrees")
	if max_degrees <= 0.0:
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
	var english_coefficient: float = item_manager.get_stat(&"paddle_english_coefficient")
	var english_angle: float = struck_paddle.velocity.y * english_coefficient
	var target_angle: float = offset_angle + english_angle
	var direction := Vector2(horizontal_sign * cos(target_angle), sin(target_angle))
	ball.linear_velocity = direction * ball.speed
