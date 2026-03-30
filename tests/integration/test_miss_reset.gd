extends GutTest

# Verifies that a miss after a streak resets all observable state atomically.
# Uses real instances wired via signals, no private method calls.

var _game: Node2D
var _ball: RigidBody2D
var _paddle: CharacterBody2D
var _manager: Node
var _mock_storage: SaveStorage
var _last_count := -1


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
				preload("res://resources/upgrades/ball_speed_min.tres"),
				preload("res://resources/upgrades/ball_speed_max.tres"),
			]
		)
	)
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball.gd").new()
	_ball._upgrade_manager = _manager

	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound

	_game = load("res://scripts/core/game.gd").new()
	_game.ball = _ball
	_game.paddle = _paddle
	add_child_autofree(_ball)
	add_child_autofree(_paddle)
	add_child_autofree(_game)
	_game.volley_count_changed.connect(func(count): _last_count = count)
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(_manager.get_value(UpgradeManager.BALL_SPEED_MIN_KEY), 0.0)


func _build_streak(hits: int) -> void:
	for i in hits:
		_paddle.on_ball_hit()
		_paddle.tracker.process(HitTracker.COOLDOWN)


func test_ball_speed_resets_after_miss() -> void:
	_build_streak(2)
	_ball.missed.emit()
	assert_almost_eq(_ball.speed, _manager.get_value(UpgradeManager.BALL_SPEED_MIN_KEY), 0.01)


func test_hud_resets_after_miss() -> void:
	_build_streak(2)
	_ball.missed.emit()
	assert_eq(_last_count, 0)


func test_pitch_resets_on_first_hit_after_miss() -> void:
	_build_streak(2)
	_ball.missed.emit()
	_paddle.tracker.process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.05, 0.001)
