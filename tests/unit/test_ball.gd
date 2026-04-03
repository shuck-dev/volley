extends GutTest

# Tests for ball speed behaviour driven by item manager stat values.
# Injects a real ItemManager with mock storage to avoid autoload dependency.

var _ball: Ball
var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	_manager._effect_manager = EffectManager.new()
	(
		_manager
		. items
		. assign(
			[
				preload("res://resources/items/ball_speed_min.tres"),
				preload("res://resources/items/ball_speed_max_range.tres"),
			]
		)
	)
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(_manager.get_stat(&"ball_speed_min"), 0.0)


func _effective_max_speed() -> float:
	return _manager.get_stat(&"ball_speed_min") + _manager.get_stat(&"ball_speed_max_range")


# --- increase_speed ---
func test_increase_speed_adds_increment() -> void:
	_ball.increase_speed()
	var expected: float = (
		_manager.get_stat(&"ball_speed_min") + _manager.get_stat(&"ball_speed_increment")
	)
	assert_almost_eq(_ball.speed, expected, 0.01)


func test_increase_speed_clamps_at_max() -> void:
	_ball.speed = _effective_max_speed()
	_ball.increase_speed()
	assert_almost_eq(_ball.speed, _effective_max_speed(), 0.01)


func test_increase_speed_does_not_exceed_max_near_ceiling() -> void:
	_ball.speed = _effective_max_speed() - 1.0
	_ball.increase_speed()
	assert_almost_eq(_ball.speed, _effective_max_speed(), 0.01)


# --- reset_speed ---
func test_reset_speed_returns_to_min() -> void:
	_ball.speed = _effective_max_speed()
	_ball.reset_speed()
	assert_almost_eq(_ball.speed, _manager.get_stat(&"ball_speed_min"), 0.01)


func test_reset_speed_preserves_direction() -> void:
	_ball.linear_velocity = Vector2(0.0, _effective_max_speed())
	_ball.reset_speed()
	assert_almost_eq(_ball.linear_velocity.x, 0.0, 0.01)
	assert_gt(_ball.linear_velocity.y, 0.0)


# --- item level changes ---
func test_min_speed_purchase_instantly_increases_speed() -> void:
	var speed_before_purchase: float = _ball.speed
	var min_before_purchase: float = _manager.get_stat(&"ball_speed_min")
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase("ball_speed_min")
	var min_after_purchase: float = _manager.get_stat(&"ball_speed_min")
	var expected_speed: float = speed_before_purchase + (min_after_purchase - min_before_purchase)
	assert_almost_eq(_ball.speed, expected_speed, 0.01)


func test_min_speed_purchase_increases_speed_above_new_min() -> void:
	_ball.speed = _manager.get_stat(&"ball_speed_min") + 200.0
	var speed_before_purchase: float = _ball.speed
	var min_before_purchase: float = _manager.get_stat(&"ball_speed_min")
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase("ball_speed_min")
	var min_after_purchase: float = _manager.get_stat(&"ball_speed_min")
	var expected_speed: float = speed_before_purchase + (min_after_purchase - min_before_purchase)
	assert_almost_eq(_ball.speed, expected_speed, 0.01)


func test_min_speed_purchase_also_raises_max_speed() -> void:
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase("ball_speed_min")
	var expected_max: float = _effective_max_speed()
	_ball.speed = expected_max - 1.0
	_ball.increase_speed()
	assert_almost_eq(_ball.speed, expected_max, 0.01)


func test_max_speed_purchase_clamps_speed_when_above_new_max() -> void:
	_ball.speed = _effective_max_speed()
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase("ball_speed_max_range")
	assert_true(_ball.speed <= _effective_max_speed())
