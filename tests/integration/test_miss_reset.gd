extends GutTest

# Verifies that a miss after a streak resets all observable state atomically.
# Uses real instances wired via signals — no private method calls.

var _game: Node2D
var _ball: RigidBody2D
var _paddle: RigidBody2D
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
	_game.volley_count_changed.connect(func(c): _last_count = c)
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(GameRules.BALL_SPEED_MIN, 0.0)


func _build_streak(hits: int) -> void:
	for i in hits:
		_paddle.on_ball_hit()
		await get_tree().create_timer(0.25).timeout


func test_ball_speed_resets_after_miss() -> void:
	await _build_streak(2)
	_ball.missed.emit()
	assert_almost_eq(_ball.speed, GameRules.BALL_SPEED_MIN, 0.01)


func test_hud_resets_after_miss() -> void:
	await _build_streak(2)
	_ball.missed.emit()
	assert_eq(_last_count, 0)


func test_pitch_resets_on_first_hit_after_miss() -> void:
	await _build_streak(2)
	_ball.missed.emit()
	await get_tree().create_timer(0.25).timeout
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.05, 0.001)
