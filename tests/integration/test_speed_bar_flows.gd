extends GutTest

# Integration tests for the speed bar across player flows: rallying raises the
# bar, missing resets it, and rallies that crack the ceiling via Cadence push
# the bar's max above its permanent-cap marker.

var _ball: Ball
var _paddle: Paddle
var _bar: Control
var _game: Node2D
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

	_game = load("res://scripts/core/court.gd").new()
	_game.ball = _ball
	_game.player_paddle = _paddle
	_game.autoplay_controller = autoplay_controller_stub
	_game._progression_config = ProgressionConfig.new()
	_game._item_manager = _manager
	_game._progression = ProgressionData.new(_mock_storage)
	add_child_autofree(_ball)
	add_child_autofree(_paddle)
	add_child_autofree(_game)
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(_manager.get_stat(&"ball_speed_min"), 0.0)

	_bar = load("res://scripts/court/speed_bar.gd").new()
	_bar.ball = _ball
	_bar.size = Vector2(200, 10)
	add_child_autofree(_bar)


func _hit_once() -> void:
	_paddle.paddle_hit.emit()
	_paddle.tracker._process(HitTracker.COOLDOWN)


func test_bar_rises_during_rally() -> void:
	var starting_speed: float = _bar.current_speed
	_hit_once()
	_hit_once()
	_hit_once()
	assert_gt(_bar.current_speed, starting_speed)


func test_bar_resets_on_miss() -> void:
	_hit_once()
	_hit_once()
	var mid_rally_speed: float = _bar.current_speed
	_ball.missed.emit()
	assert_lt(_bar.current_speed, mid_rally_speed)
	assert_eq(_bar.current_speed, _ball.min_speed)
