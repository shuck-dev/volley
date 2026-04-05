class_name BallEffectProcessor
extends Node

var paddles: Array[Node2D] = []

var _ball: Ball
var _item_manager: Node
var _speed_offset := 0.0


func _ready() -> void:
	_ball = get_parent() as Ball
	assert(_ball != null, "BallEffectProcessor must be a child of Ball")
	if _item_manager == null:
		_item_manager = ItemManager


func process_frame(delta: float) -> void:
	_apply_magnetism(delta)
	_sync_speed_limits()


func _sync_speed_limits() -> void:
	var new_min: float = _item_manager.get_stat(&"ball_speed_min")
	if not is_equal_approx(new_min, _ball.min_speed):
		_ball.speed += new_min - _ball.min_speed
		_ball.min_speed = new_min
	_ball.max_speed = _ball.min_speed + _item_manager.get_stat(&"ball_speed_max_range")
	_ball.speed_increment = _item_manager.get_stat(&"ball_speed_increment")

	var new_offset: float = _item_manager.get_stat(&"ball_speed_offset")
	_ball.speed += new_offset - _speed_offset
	_speed_offset = new_offset

	_ball.speed = clampf(_ball.speed, _ball.min_speed, _ball.max_speed)


func process_hit() -> void:
	_apply_return_angle_influence()


func _apply_magnetism(delta: float) -> void:
	var magnetism: float = _item_manager.get_stat(&"ball_magnetism")
	if magnetism <= 0.0 or paddles.is_empty():
		return

	var closest_paddle: Node2D = null
	var closest_distance := INF
	for paddle in paddles:
		if not is_instance_valid(paddle):
			continue
		var distance: float = _ball.global_position.distance_to(paddle.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_paddle = paddle

	if closest_paddle == null:
		return

	var pull_direction: Vector2 = (
		(closest_paddle.global_position - _ball.global_position).normalized()
	)
	var pull_strength: float = magnetism * delta
	var new_direction: Vector2 = (
		(_ball.linear_velocity.normalized() + pull_direction * pull_strength).normalized()
	)
	_ball.linear_velocity = new_direction * _ball.speed


func _apply_return_angle_influence() -> void:
	var influence: float = _item_manager.get_stat(&"return_angle_influence")
	if influence <= 0.0:
		return

	var horizontal := Vector2(signf(_ball.linear_velocity.x), 0.0)
	if horizontal == Vector2.ZERO:
		return

	var current_direction: Vector2 = _ball.linear_velocity.normalized()
	var biased_direction: Vector2 = current_direction.lerp(horizontal, influence).normalized()
	_ball.linear_velocity = biased_direction * _ball.speed
