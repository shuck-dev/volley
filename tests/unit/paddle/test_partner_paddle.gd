extends GutTest

# Verifies the partner paddle uses base stats and ignores player upgrades.

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
				preload("res://resources/items/ankle_weights.tres"),
				preload("res://resources/items/grip_tape.tres"),
			]
		)
	)
	add_child_autofree(_manager)


func _create_partner_paddle() -> PartnerPaddle:
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(20.0, 80.0)

	var paddle: PartnerPaddle = load("res://scripts/entities/partner_paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	var controller: PartnerAIController = load("res://scripts/core/partner_ai_controller.gd").new()
	var config := PaddleAIConfig.new()
	config.reaction_delay_frames = 1
	controller.config = config
	paddle.add_child(sound)
	paddle.add_child(collision)
	paddle.add_child(tracker)
	paddle.add_child(controller)
	paddle.hit_sound = sound
	paddle.collision = collision
	paddle.tracker = tracker
	paddle.controller = controller

	add_child_autofree(paddle)
	return paddle


# --- speed uses base stats ---
func test_speed_equals_base_stat() -> void:
	var paddle := _create_partner_paddle()
	var expected: float = GameRules.base_stats[&"paddle_speed"]
	assert_almost_eq(paddle.get_speed(), expected, 0.01)


func test_speed_unchanged_after_player_purchases_ankle_weights() -> void:
	var paddle := _create_partner_paddle()
	var speed_before: float = paddle.get_speed()

	_manager._progression.friendship_point_balance = 1000
	_manager.purchase("ankle_weights")

	assert_almost_eq(paddle.get_speed(), speed_before, 0.01)


# --- size uses base stats ---
func test_size_equals_base_stat() -> void:
	var paddle := _create_partner_paddle()
	var expected: float = GameRules.base_stats[&"paddle_size"]
	assert_almost_eq(paddle.collision.shape.size.y, expected, 0.01)


func test_size_unchanged_after_player_purchases_grip_tape() -> void:
	var paddle := _create_partner_paddle()
	var size_before: float = paddle.collision.shape.size.y

	_manager._progression.friendship_point_balance = 1000
	_manager.purchase("grip_tape")

	assert_almost_eq(paddle.collision.shape.size.y, size_before, 0.01)


# --- not connected to item_level_changed ---
func test_not_connected_to_item_level_changed() -> void:
	var paddle := _create_partner_paddle()
	assert_false(
		_manager.item_level_changed.is_connected(paddle._on_item_level_changed),
		"Partner paddle should not connect to item_level_changed"
	)
