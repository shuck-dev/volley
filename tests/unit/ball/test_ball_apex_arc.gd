extends GutTest

const BOUND_Y := -100.0

var _ball: Ball


func before_each() -> void:
	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball.bound_y = BOUND_Y
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(_ball.min_speed, 0.0)


func test_normal_to_arc_on_upward_cross() -> void:
	watch_signals(_ball)
	_ball.global_position = Vector2(0.0, BOUND_Y - 10.0)
	_ball._physics_process(0.016)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.PLAY_ARC])


func test_arc_to_normal_on_downward_cross() -> void:
	watch_signals(_ball)
	_ball.set_play_state(Ball.PlayState.PLAY_ARC)
	_ball.global_position = Vector2(0.0, BOUND_Y + 10.0)
	_ball._physics_process(0.016)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.PLAY_NORMAL])
