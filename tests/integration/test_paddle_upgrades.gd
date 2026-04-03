extends GutTest

# Verifies paddle collision size reflects upgrade values.
# Uses real upgrade .tres resources so base_value/effect_per_level drive expectations.

var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/progression/upgrade_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	(
		_manager
		. upgrades
		. assign(
			[
				preload("res://resources/upgrades/paddle_speed.tres"),
				preload("res://resources/upgrades/paddle_size.tres"),
				preload("res://resources/upgrades/ball_speed_min.tres"),
			]
		)
	)
	add_child_autofree(_manager)


func _create_paddle() -> CharacterBody2D:
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(20.0, 80.0)

	var paddle: Paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	paddle.add_child(sound)
	paddle.add_child(collision)
	paddle.hit_sound = sound
	paddle.collision = collision
	paddle._upgrade_manager = _manager

	add_child_autofree(paddle)
	return paddle


# --- size ---
func test_apply_size_sets_collision_to_base_value_at_level_zero() -> void:
	var paddle := _create_paddle()
	var expected: float = _manager.get_base_value(UpgradeManager.PADDLE_SIZE_KEY)
	assert_almost_eq(paddle.collision.shape.size.y, expected, 0.01)


func test_apply_size_increases_by_effect_per_level_after_purchase() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(UpgradeManager.PADDLE_SIZE_KEY)

	var paddle := _create_paddle()
	var expected: float = _manager.get_value(UpgradeManager.PADDLE_SIZE_KEY)
	assert_almost_eq(paddle.collision.shape.size.y, expected, 0.01)


func test_size_updates_live_on_purchase() -> void:
	var paddle := _create_paddle()
	assert_almost_eq(
		paddle.collision.shape.size.y, _manager.get_base_value(UpgradeManager.PADDLE_SIZE_KEY), 0.01
	)

	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(UpgradeManager.PADDLE_SIZE_KEY)
	assert_almost_eq(
		paddle.collision.shape.size.y, _manager.get_value(UpgradeManager.PADDLE_SIZE_KEY), 0.01
	)


func test_size_updates_live_on_remove_level() -> void:
	_manager._progression.friendship_point_balance = 1000
	_manager.purchase(UpgradeManager.PADDLE_SIZE_KEY)
	var paddle := _create_paddle()

	_manager.remove_level(UpgradeManager.PADDLE_SIZE_KEY)
	assert_almost_eq(
		paddle.collision.shape.size.y, _manager.get_base_value(UpgradeManager.PADDLE_SIZE_KEY), 0.01
	)
