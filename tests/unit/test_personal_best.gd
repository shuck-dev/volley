extends GutTest

# Verifies personal volley best tracking — updates on new highs, persists across misses,
# and does not update when a streak falls short of the existing record.

var _game: Node2D
var _ball_stub: RigidBody2D
var _paddle_stub: Node
var _last_personal_best := -1


func before_each() -> void:
	_ball_stub = load("res://tests/stubs/ball_stub.gd").new()
	_paddle_stub = load("res://tests/stubs/paddle_stub.gd").new()

	_game = load("res://scripts/game.gd").new()
	_game.ball = _ball_stub
	_game.paddle = _paddle_stub
	add_child_autofree(_ball_stub)
	add_child_autofree(_paddle_stub)
	add_child_autofree(_game)
	_game.personal_best_changed.connect(func(best): _last_personal_best = best)
	_ball_stub.gravity_scale = 0.0


func _hit() -> void:
	_paddle_stub.paddle_hit.emit()


func test_personal_best_updates_on_new_high() -> void:
	_hit()
	_hit()
	_hit()
	assert_eq(_last_personal_best, 3)


func test_personal_best_persists_after_miss() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	assert_eq(_last_personal_best, 3)


func test_personal_best_not_updated_when_streak_below_record() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	_hit()
	# One hit after miss — streak is 1, best is 3, so no new update
	assert_eq(_last_personal_best, 3)
