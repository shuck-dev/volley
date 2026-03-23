extends GutTest

var _ball: RigidBody2D


func before_each() -> void:
	_ball = load("res://scripts/ball.gd").new()
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(GameRules.BALL_SPEED_MIN, 0.0)


# --- increase_speed ---


func test_increase_speed_adds_increment() -> void:
	_ball.increase_speed()
	assert_almost_eq(_ball.speed, GameRules.BALL_SPEED_MIN + GameRules.BALL_SPEED_INCREMENT, 0.01)


func test_increase_speed_clamps_at_max() -> void:
	_ball.speed = GameRules.BALL_SPEED_MAX
	_ball.increase_speed()
	assert_almost_eq(_ball.speed, GameRules.BALL_SPEED_MAX, 0.01)


func test_increase_speed_does_not_exceed_max_near_ceiling() -> void:
	_ball.speed = GameRules.BALL_SPEED_MAX - 1.0
	_ball.increase_speed()
	assert_almost_eq(_ball.speed, GameRules.BALL_SPEED_MAX, 0.01)


# --- reset_speed ---


func test_reset_speed_returns_to_min() -> void:
	_ball.speed = GameRules.BALL_SPEED_MAX
	_ball.reset_speed()
	assert_almost_eq(_ball.speed, GameRules.BALL_SPEED_MIN, 0.01)


func test_reset_speed_preserves_direction() -> void:
	_ball.linear_velocity = Vector2(0.0, GameRules.BALL_SPEED_MAX)
	_ball.reset_speed()
	assert_almost_eq(_ball.linear_velocity.x, 0.0, 0.01)
	assert_gt(_ball.linear_velocity.y, 0.0)
