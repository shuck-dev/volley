extends GutTest

# Verifies personal volley best tracking — updates on new highs, persists across misses,
# and does not update when a streak falls short of the existing record.

var _game: Node2D
var _ball: RigidBody2D
var _paddle: RigidBody2D
var _last_personal_best := -1


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
	_game.personal_best_changed.connect(func(best): _last_personal_best = best)
	_ball.gravity_scale = 0.0
	_ball.linear_velocity = Vector2(GameRules.BALL_SPEED_MIN, 0.0)


func _hit() -> void:
	_paddle.on_ball_hit()
	await get_tree().create_timer(0.25).timeout


func test_personal_best_updates_on_new_high() -> void:
	await _hit()
	await _hit()
	await _hit()
	assert_eq(_last_personal_best, 3)


func test_personal_best_persists_after_miss() -> void:
	await _hit()
	await _hit()
	await _hit()
	_ball.missed.emit()
	assert_eq(_last_personal_best, 3)


func test_personal_best_not_updated_when_streak_below_record() -> void:
	await _hit()
	await _hit()
	await _hit()
	_ball.missed.emit()
	await get_tree().create_timer(0.25).timeout
	await _hit()
	# One hit after miss — streak is 1, best is 3, so no new update
	assert_eq(_last_personal_best, 3)
