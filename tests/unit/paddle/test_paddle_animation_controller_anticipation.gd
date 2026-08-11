extends GutTest

# Tests for PaddleAnimationController.tick_anticipation: the swing-lead-time trigger
# that starts the swing early enough for its contact frame to land on ball arrival.

const PADDLE_X := -700.0
# Player-side lane: a ball approaches when its velocity opposes the paddle's own-side sign.
const LANE_SIGN := 1.0
const LEAD_TIME := 0.6

var _controller: PaddleAnimationController
var _reconciler: BallReconciler


func before_each() -> void:
	_controller = load("res://scripts/core/paddle_animation_controller.gd").new(0.0)
	_reconciler = load("res://scripts/items/ball_reconciler.gd").new()
	add_child_autofree(_reconciler)


func _spawn_ball(position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = load("res://tests/stubs/ball_stub.gd").new()
	add_child_autofree(ball)
	ball.position = position
	ball.linear_velocity = velocity
	_reconciler.attach(ball)
	return ball


# time_to_contact = LEAD_TIME exactly, at 200px/s: distance = 120px.
func test_fires_swing_when_time_to_contact_is_at_the_lead_time_threshold() -> void:
	_spawn_ball(Vector2(PADDLE_X + 120.0, 0.0), Vector2(-200.0, 0.0))

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)

	assert_eq(_controller.get_state(), &"swing_grounded")


func test_does_not_fire_before_the_lead_time_threshold() -> void:
	# distance = 130px at 200px/s -> time_to_contact = 0.65s, past the 0.6s lead time.
	_spawn_ball(Vector2(PADDLE_X + 130.0, 0.0), Vector2(-200.0, 0.0))

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)

	assert_ne(_controller.get_state(), &"swing_grounded")


func test_fires_swing_flying_when_airborne() -> void:
	_spawn_ball(Vector2(PADDLE_X + 120.0, 0.0), Vector2(-200.0, 0.0))

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, false)

	assert_eq(_controller.get_state(), &"swing_flying")


func test_fires_once_then_does_not_refire_across_ticks_for_the_same_ball() -> void:
	_spawn_ball(Vector2(PADDLE_X + 120.0, 0.0), Vector2(-200.0, 0.0))

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)
	assert_eq(_controller.get_state(), &"swing_grounded")

	_controller.on_swing_finished(true, false)
	assert_eq(_controller.get_state(), &"ready_grounded", "swing resolves back to ready")

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)
	assert_eq(
		_controller.get_state(),
		&"ready_grounded",
		"the same ball instance does not retrigger anticipation once it already fired",
	)


func test_does_not_fire_when_a_swing_is_already_pending() -> void:
	var real_hit_ball: Ball = _spawn_ball(Vector2(PADDLE_X + 5.0, 0.0), Vector2(-500.0, 0.0))
	_controller.on_hit(true, false)
	assert_eq(_controller.get_state(), &"swing_grounded")

	var other_ball: Ball = _spawn_ball(Vector2(PADDLE_X + 120.0, 100.0), Vector2(-200.0, 0.0))
	real_hit_ball.linear_velocity = Vector2.ZERO

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)

	assert_eq(
		_controller.get_state(),
		&"swing_grounded",
		"an already-pending swing is not restarted by a newly-anticipated ball",
	)
	assert_ne(other_ball, null)


func test_resets_guard_and_refires_when_the_ball_reverses_direction() -> void:
	var ball: Ball = _spawn_ball(Vector2(PADDLE_X + 120.0, 0.0), Vector2(-200.0, 0.0))

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)
	assert_eq(_controller.get_state(), &"swing_grounded")
	_controller.on_swing_finished(true, false)

	# Ball bounces back toward the far side: no longer approaching this lane.
	ball.linear_velocity = Vector2(200.0, 0.0)
	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)
	assert_eq(_controller.get_state(), &"ready_grounded", "a receding ball does not re-anticipate")

	# Ball reverses back toward the paddle within lead-time range: fires again.
	ball.position = Vector2(PADDLE_X + 120.0, 0.0)
	ball.linear_velocity = Vector2(-200.0, 0.0)
	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)
	assert_eq(
		_controller.get_state(),
		&"swing_grounded",
		"reversing back toward the paddle resets the per-ball guard",
	)


func test_resets_guard_when_the_ball_is_actually_hit() -> void:
	_spawn_ball(Vector2(PADDLE_X + 120.0, 0.0), Vector2(-200.0, 0.0))

	_controller.tick_anticipation(_reconciler, PADDLE_X, LANE_SIGN, true)
	assert_eq(_controller.get_state(), &"swing_grounded")

	_controller.on_hit(true, false)
	_controller.on_swing_finished(true, false)

	assert_eq(_controller.get_state(), &"ready_grounded")


func test_does_not_fire_when_no_reconciler_is_bound() -> void:
	_controller.tick(0.0, true, false)

	_controller.tick_anticipation(null, PADDLE_X, LANE_SIGN, true)

	assert_eq(_controller.get_state(), &"ready_grounded")
