extends GutTest

# Verifies ball speed, pitch, and HUD stay consistent across a growing rally.
# Uses real instances wired via signals — no private method calls.

var _game: Node2D
var _ball: RigidBody2D
var _paddle: CharacterBody2D
var _last_count := -1


func before_each() -> void:
	_ball = load("res://scripts/ball.gd").new()

	_paddle = load("res://scripts/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound

	_game = load("res://scripts/game.gd").new()
	_game.ball = _ball
	_game.paddle = _paddle
	add_child_autofree(_ball)
	add_child_autofree(_paddle)
	add_child_autofree(_game)
	_game.volley_count_changed.connect(func(count): _last_count = count)
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(GameRules.BALL_SPEED_MIN, 0.0)


func _hit() -> void:
	_paddle.on_ball_hit()
	await get_tree().create_timer(0.25).timeout


func test_ball_speed_increases_across_three_hits() -> void:
	await _hit()
	await _hit()
	await _hit()
	var expected := minf(
		GameRules.BALL_SPEED_MIN + 3.0 * GameRules.BALL_SPEED_INCREMENT, GameRules.BALL_SPEED_MAX
	)
	assert_almost_eq(_ball.speed, expected, 0.01)


func test_pitch_increases_across_three_hits() -> void:
	await _hit()
	await _hit()
	await _hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.0 + 3 * 0.05, 0.001)


func test_hud_reflects_hit_count() -> void:
	await _hit()
	await _hit()
	await _hit()
	assert_eq(_last_count, 3)

# NOTE: the path from physics body_entered → _on_body_entered → on_ball_hit/missed.emit
# is not covered by these tests. That dispatch requires real physics and is intentionally
# left as a known gap — it's two lines that rarely change and a gameplay test isn't worth the cost.
