extends GutTest

# Tests for BallReconciler.get_closest_approaching_ball: the multi-ball ranking
# both PaddleAIController and PaddleAnimationController's anticipation trigger share.

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const PADDLE_X := -700.0
# Player-side lane: a ball approaches when its velocity opposes the paddle's own-side sign.
const LANE_SIGN := 1.0

var _reconciler: BallReconciler


func before_each() -> void:
	_reconciler = BallReconcilerScript.new()
	add_child_autofree(_reconciler)


func _spawn_ball(position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = load("res://tests/stubs/ball_stub.gd").new()
	add_child_autofree(ball)
	ball.position = position
	ball.linear_velocity = velocity
	return ball


func test_returns_null_when_no_balls_tracked() -> void:
	assert_null(_reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN))


func test_returns_null_when_no_ball_approaches() -> void:
	var away_ball: Ball = _spawn_ball(Vector2(-500.0, 0.0), Vector2(100.0, 0.0))
	_reconciler.attach(away_ball)

	assert_null(_reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN))


func test_skips_ball_below_minimum_horizontal_speed() -> void:
	var slow_ball: Ball = _spawn_ball(Vector2(-500.0, 0.0), Vector2(-0.5, 0.0))
	_reconciler.attach(slow_ball)

	assert_null(_reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN))


func test_selects_the_soonest_arriving_of_two_approaching_balls() -> void:
	var near_ball: Ball = _spawn_ball(Vector2(PADDLE_X + 50.0, 0.0), Vector2(-200.0, 0.0))
	var far_ball: Ball = _spawn_ball(Vector2(0.0, 0.0), Vector2(-100.0, 0.0))
	_reconciler.attach(far_ball)
	_reconciler.attach(near_ball)

	var closest: Ball = _reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN)

	assert_eq(closest, near_ball, "the soonest-arriving ball wins regardless of attach order")


func test_ignores_the_away_ball_and_returns_the_approaching_one() -> void:
	var approaching_ball: Ball = _spawn_ball(Vector2(PADDLE_X + 200.0, 0.0), Vector2(-100.0, 0.0))
	var away_ball: Ball = _spawn_ball(Vector2(PADDLE_X + 10.0, 0.0), Vector2(400.0, 0.0))
	_reconciler.attach(away_ball)
	_reconciler.attach(approaching_ball)

	var closest: Ball = _reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN)

	assert_eq(closest, approaching_ball)


func test_ignores_ball_not_in_play() -> void:
	var stored_ball: Ball = _spawn_ball(Vector2(PADDLE_X + 100.0, 0.0), Vector2(-100.0, 0.0))
	stored_ball.set_play_state(Ball.PlayState.STORED)
	_reconciler.attach(stored_ball)

	assert_null(_reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN))


func test_flips_direction_filter_for_the_opposite_lane_sign() -> void:
	# Same ball, opposite paddle side: velocity that approaches the right-side paddle
	# moves away from the left-side one, so flipping lane_sign flips who sees it.
	var ball: Ball = _spawn_ball(Vector2(0.0, 0.0), Vector2(100.0, 0.0))
	_reconciler.attach(ball)

	assert_null(_reconciler.get_closest_approaching_ball(PADDLE_X, LANE_SIGN))
	assert_eq(_reconciler.get_closest_approaching_ball(700.0, -1.0), ball)
