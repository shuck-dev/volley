extends GutTest

var _ball: RigidBody2D


func before_each() -> void:
	var ball_speed_upgrade := Upgrade.new()
	ball_speed_upgrade.effect_key = UpgradeManager.BALL_SPEED_MIN_KEY
	ball_speed_upgrade.base_value = GameRules.BALL_SPEED_MIN
	ball_speed_upgrade.effect_per_level = 0.0
	ball_speed_upgrade.max_level = 5
	ball_speed_upgrade.base_cost = 100
	UpgradeManager.upgrades.assign([ball_speed_upgrade])

	_ball = load("res://scripts/entities/ball.gd").new()
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(GameRules.BALL_SPEED_MIN, 0.0)


func after_each() -> void:
	UpgradeManager.upgrades.clear()


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
