extends GutTest

# Verifies friendship point tracking — FP is a currency that
# increments on each hit and persists across misses (shop mechanics will decrease it).

var _game: Node2D
var _ball_stub: RigidBody2D
var _paddle_stub: Node
var _last_friendship_total := -1


func before_each() -> void:
	_ball_stub = load("res://tests/stubs/ball_stub.gd").new()
	_paddle_stub = load("res://tests/stubs/paddle_stub.gd").new()

	_game = load("res://scripts/core/game.gd").new()
	_game.ball = _ball_stub
	_game.paddle = _paddle_stub
	add_child_autofree(_ball_stub)
	add_child_autofree(_paddle_stub)
	add_child_autofree(_game)
	_game.friendship_total_changed.connect(func(total): _last_friendship_total = total)
	_ball_stub.gravity_scale = 0.0


func _hit() -> void:
	_paddle_stub.paddle_hit.emit()


func test_fp_increments_on_each_hit() -> void:
	_hit()
	assert_eq(_last_friendship_total, 1)
	_hit()
	assert_eq(_last_friendship_total, 2)
	_hit()
	assert_eq(_last_friendship_total, 3)


func test_fp_persists_after_miss() -> void:
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	assert_eq(_last_friendship_total, 3)


func test_fp_accumulates_across_multiple_rallies() -> void:
	_hit()
	_hit()
	_ball_stub.missed.emit()
	_hit()
	_hit()
	_hit()
	_ball_stub.missed.emit()
	assert_eq(_last_friendship_total, 5)
