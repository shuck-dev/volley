extends GutTest

# Verifies that game.gd dispatches ball events to the effect system.
# Uses Cadence as the test item since it consumes both on_max_speed_reached and on_miss.

var _game: Node2D
var _ball: Ball
var _paddle: Paddle
var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([preload("res://resources/items/cadence.tres")])
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._item_manager = _manager

	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)

	var autoplay_controller_stub: Node = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(autoplay_controller_stub)

	_game = load("res://scripts/core/game.gd").new()
	_game.ball = _ball
	_game.paddle = _paddle
	_game.autoplay_controller = autoplay_controller_stub
	_game._progression_config = ProgressionConfig.new()
	_game._item_manager = _manager
	add_child_autofree(_ball)
	add_child_autofree(_paddle)
	add_child_autofree(_game)
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(_manager.get_stat(&"ball_speed_min"), 0.0)


func _purchase_cadence() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("cadence")


func _hit_until_max_speed() -> void:
	while _ball.speed < _ball.max_speed:
		_paddle.on_ball_hit()
		_paddle.tracker._process(HitTracker.COOLDOWN)


# --- on_max_speed_reached wiring ---
func test_ceiling_raises_when_ball_reaches_max_speed() -> void:
	_purchase_cadence()
	var base_range: float = GameRules.base_stats[&"ball_speed_max_range"]

	_hit_until_max_speed()

	assert_gt(
		_manager.get_stat(&"ball_speed_max_range"),
		base_range,
		"ball_speed_max_range should increase after ball hits ceiling",
	)


# --- on_miss wiring ---
func test_ceiling_raise_resets_on_miss() -> void:
	_purchase_cadence()
	_hit_until_max_speed()

	_ball.missed.emit()

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.base_stats[&"ball_speed_max_range"],
		"ball_speed_max_range should reset to base after miss",
	)
