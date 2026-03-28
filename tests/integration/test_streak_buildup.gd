extends GutTest

# Verifies ball speed escalates correctly across a growing rally.
# Uses real instances wired via signals — no private method calls.

var _game: Node2D
var _ball: RigidBody2D
var _paddle: CharacterBody2D


func before_each() -> void:
	_ball = load("res://scripts/entities/ball.gd").new()

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
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(GameRules.BALL_SPEED_MIN, 0.0)


func test_ball_speed_increases_across_three_hits() -> void:
	_paddle.on_ball_hit()
	_paddle.tracker.process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	_paddle.tracker.process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	var expected := minf(
		GameRules.BALL_SPEED_MIN + 3.0 * GameRules.BALL_SPEED_INCREMENT, GameRules.BALL_SPEED_MAX
	)
	assert_almost_eq(_ball.speed, expected, 0.01)
