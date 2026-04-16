extends GutTest

# Verifies personal volley best tracking: updates on new highs, persists across misses,
# and does not update when a streak falls short of the existing record.

var _game: Node2D
var _ball_stub: Ball
var _paddle_stub: Paddle
var _last_personal_volley_best := -1


func before_each() -> void:
	_ball_stub = load("res://tests/stubs/ball_stub.gd").new()
	_paddle_stub = load("res://tests/stubs/paddle_stub.gd").new()

	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	var autoplay_controller_stub: Node = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(autoplay_controller_stub)

	_game = load("res://scripts/core/court.gd").new()
	_game.ball = _ball_stub
	_game.player_paddle = _paddle_stub
	_game.autoplay_controller = autoplay_controller_stub
	_game._progression_config = ProgressionConfig.new()
	_game._progression = ProgressionData.new(mock_storage)
	add_child_autofree(_ball_stub)
	add_child_autofree(_paddle_stub)
	add_child_autofree(_game)
	_game.personal_volley_best_changed.connect(func(best): _last_personal_volley_best = best)
	_ball_stub.gravity_scale = 0.0


func _hit() -> void:
	_paddle_stub.paddle_hit.emit()


func test_personal_volley_best_updates_on_new_high() -> void:
	_hit()
	_hit()
	_hit()
	assert_eq(_last_personal_volley_best, 3)


func test_personal_volley_best_persists_after_miss() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	assert_eq(_last_personal_volley_best, 3)


func test_personal_volley_best_not_updated_when_streak_below_record() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	_hit()
	# One hit after miss: streak is 1, best is 3, so no new update
	assert_eq(_last_personal_volley_best, 3)
