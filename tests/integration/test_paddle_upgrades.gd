extends GutTest

# Verifies paddle collision size reflects item stat values.
# Uses real item .tres resources so stat values drive expectations.

var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	(
		_manager
		. items
		. assign(
			[
				preload("res://resources/items/ankle_weights.tres"),
				preload("res://resources/items/grip_tape.tres"),
				preload("res://resources/items/training_ball.tres"),
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
	paddle._item_manager = _manager

	add_child_autofree(paddle)
	return paddle


# --- size ---
func test_apply_size_sets_collision_to_base_value_at_level_zero() -> void:
	var paddle := _create_paddle()
	var expected: float = Stats.resolve(GameRules.paddle.paddle_size, &"paddle_size", _manager)
	assert_almost_eq(paddle.collision.shape.size.y, expected, 0.01)


func test_apply_size_increases_by_effect_per_level_after_purchase() -> void:
	_manager.economy.friendship_point_balance = 1000
	_manager.purchase("grip_tape")

	var paddle := _create_paddle()
	var expected: float = Stats.resolve(GameRules.paddle.paddle_size, &"paddle_size", _manager)
	assert_almost_eq(paddle.collision.shape.size.y, expected, 0.01)


func test_size_updates_live_on_purchase() -> void:
	var paddle := _create_paddle()
	assert_almost_eq(
		paddle.collision.shape.size.y,
		Stats.resolve(GameRules.paddle.paddle_size, &"paddle_size", _manager),
		0.01
	)

	_manager.economy.friendship_point_balance = 1000
	_manager.purchase("grip_tape")
	assert_almost_eq(
		paddle.collision.shape.size.y,
		Stats.resolve(GameRules.paddle.paddle_size, &"paddle_size", _manager),
		0.01
	)


func test_size_updates_live_on_remove_level() -> void:
	_manager.economy.friendship_point_balance = 1000
	_manager.purchase("grip_tape")
	var paddle := _create_paddle()

	_manager.remove_level("grip_tape")
	assert_almost_eq(
		paddle.collision.shape.size.y,
		Stats.resolve(GameRules.paddle.paddle_size, &"paddle_size", _manager),
		0.01
	)
