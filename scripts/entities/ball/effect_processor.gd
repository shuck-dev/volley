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


func process_hit() -> void:
	_apply_return_angle_influence()


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


func _apply_return_angle_influence() -> void:
	var influence: float = item_manager.get_stat(&"return_angle_influence")
	if influence <= 0.0:
		return

	var horizontal := Vector2(signf(ball.linear_velocity.x), 0.0)
	if horizontal == Vector2.ZERO:
		return

	var current_direction: Vector2 = ball.linear_velocity.normalized()
	var biased_direction: Vector2 = current_direction.lerp(horizontal, influence).normalized()
	ball.linear_velocity = biased_direction * ball.speed
