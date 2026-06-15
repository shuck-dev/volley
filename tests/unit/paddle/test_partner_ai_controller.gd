extends GutTest

# Tests for PartnerAIController behaviour: tracking, drifting, dodging.

const BallStub: GDScript = preload("res://tests/stubs/ball_stub.gd")
const PHYSICS_DELTA := 0.016
const PADDLE_X := 300.0
const BALL_APPROACHING_PARTNER := Vector2(100.0, 0.0)
const BALL_MOVING_AWAY := Vector2(-100.0, 0.0)

var _controller: PartnerAIController
var _paddle: Paddle
var _ball: Ball
var _config: PaddleAIConfig


func before_each() -> void:
	_ball = BallStub.new()
	add_child_autofree(_ball)

	_paddle = load("res://scripts/entities/paddle.gd").new()
	_paddle.position = Vector2(PADDLE_X, 0.0)
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	add_child_autofree(_paddle)

	_config = PaddleAIConfig.new()
	_config.reaction_delay_frames = 1
	_config.speed_scale = 0.70
	_config.noise = 0.0
	_config.velocity_smoothing = 1.0
	_config.snap_threshold = 0.0

	_controller = load("res://scripts/core/partner_ai_controller.gd").new()
	_controller.paddle = _paddle
	_controller.config = _config
	add_child_autofree(_controller)
	_controller.ball = _ball
	_controller.set_enabled(true)


func _run_frames(count: int) -> void:
	for _frame in range(count):
		_controller._physics_process(PHYSICS_DELTA)


func _spawn_ball(position: Vector2, velocity: Vector2) -> Ball:
	var ball: Ball = BallStub.new()
	ball.position = position
	ball.linear_velocity = velocity
	add_child_autofree(ball)
	return ball


# --- tracking ---
func test_moves_toward_ball_when_approaching() -> void:
	_ball.position = Vector2(100.0, 200.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_run_frames(5)
	assert_gt(_paddle.velocity.y, 0.0, "should move down toward ball at y=200")


func test_moves_up_toward_ball_above() -> void:
	_ball.position = Vector2(100.0, -200.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_run_frames(5)
	assert_lt(_paddle.velocity.y, 0.0, "should move up toward ball at y=-200")


# --- drifting ---
func test_drifts_toward_center_when_ball_moving_away() -> void:
	_ball.position = Vector2(100.0, 0.0)
	_ball.linear_velocity = BALL_MOVING_AWAY
	_paddle.position = Vector2(PADDLE_X, 200.0)

	_run_frames(10)
	assert_lt(_paddle.velocity.y, 0.0, "should drift up toward center")


func test_drifts_toward_center_when_ball_is_behind_paddle() -> void:
	# Ball past the paddle's x position (was the _dodge trigger pre-removal). The fallback now drifts
	# the paddle toward y=0 so it's ready for the next serve.
	_ball.position = Vector2(PADDLE_X + 50.0, 0.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_paddle.position = Vector2(PADDLE_X, 200.0)

	_run_frames(10)
	assert_lt(
		_paddle.velocity.y, 0.0, "ball-behind paddle should drift toward center, not move freely"
	)


# --- noise resampling ---
func test_noise_offset_changes_when_ball_reverses_direction() -> void:
	_config.noise = 50.0
	_ball.position = Vector2(100.0, 200.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_run_frames(3)
	var first_offset: float = _controller._noise_offset

	_ball.linear_velocity = BALL_MOVING_AWAY
	_run_frames(1)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_run_frames(1)
	var second_offset: float = _controller._noise_offset

	# With noise=50, two independent samples matching is negligible
	assert_ne(first_offset, second_offset, "noise should resample on direction change")


func test_noise_offset_holds_during_same_flight() -> void:
	_config.noise = 50.0
	_ball.position = Vector2(100.0, 200.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_run_frames(3)
	var first_offset: float = _controller._noise_offset

	_run_frames(10)
	var second_offset: float = _controller._noise_offset

	assert_eq(first_offset, second_offset, "noise should hold during same flight")


func test_noise_resamples_during_drift_when_direction_changes() -> void:
	_config.noise = 50.0
	_ball.position = Vector2(100.0, 0.0)
	_ball.linear_velocity = BALL_MOVING_AWAY
	_run_frames(3)
	var offset_during_drift: float = _controller._noise_offset

	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_run_frames(1)
	var offset_after_reversal: float = _controller._noise_offset

	assert_ne(
		offset_during_drift,
		offset_after_reversal,
		"noise should resample even when direction changes during drift",
	)


# With two live approaching balls the partner covers the soonest-arriving one.
func _bind_tracker_for_multiball() -> BallReconciler:
	var tracker: BallReconciler = load("res://scripts/items/ball_reconciler.gd").new()
	add_child_autofree(tracker)
	_controller.bind_tracker(tracker)
	return tracker


func test_commits_to_soonest_arriving_of_two_live_balls() -> void:
	var tracker: BallReconciler = _bind_tracker_for_multiball()

	# Near ball: close x, fast → tiny time-to-arrival.
	var near_ball: Ball = _spawn_ball(Vector2(PADDLE_X - 50.0, 200.0), Vector2(200.0, 0.0))
	# Far ball: distant x, slow → large time-to-arrival.
	var far_ball: Ball = _spawn_ball(Vector2(0.0, -200.0), Vector2(100.0, 0.0))
	# Attach far last so the signal-bound ball is far_ball; selection must override it.
	tracker.attach(near_ball)
	tracker.attach(far_ball)
	assert_eq(_controller.ball, far_ball, "precondition: signal-bound ball is the far ball")

	_run_frames(5)

	assert_eq(_controller.ball, near_ball, "partner selects the soonest-arriving ball")


func test_ignores_away_ball_and_tracks_the_approaching_one() -> void:
	var tracker: BallReconciler = _bind_tracker_for_multiball()

	# Velocities set after attach: Ball._ready resets linear_velocity to its serve vector.
	var approaching_ball: Ball = _spawn_ball(Vector2(PADDLE_X - 200.0, 200.0), Vector2.ZERO)
	var away_ball: Ball = _spawn_ball(Vector2(PADDLE_X - 10.0, -200.0), Vector2.ZERO)
	tracker.attach(approaching_ball)
	tracker.attach(away_ball)
	approaching_ball.linear_velocity = Vector2(100.0, 0.0)
	away_ball.linear_velocity = Vector2(-400.0, 0.0)
	assert_eq(_controller.ball, away_ball, "precondition: signal-bound ball is the away ball")

	_run_frames(5)

	assert_eq(_controller.ball, approaching_ball, "partner skips the away ball for the approacher")


func test_switches_when_a_sooner_ball_appears() -> void:
	var tracker: BallReconciler = _bind_tracker_for_multiball()

	var first_ball: Ball = _spawn_ball(Vector2(PADDLE_X - 50.0, 200.0), Vector2(200.0, 0.0))
	tracker.attach(first_ball)
	_run_frames(5)
	assert_gt(_paddle.velocity.y, 0.0, "precondition: partner tracks the first ball below center")

	# A sooner ball appears: nearly at the paddle, very fast, intercept above center.
	var sooner_ball: Ball = _spawn_ball(Vector2(PADDLE_X - 10.0, -200.0), Vector2(400.0, 0.0))
	tracker.attach(sooner_ball)
	# A slow straggler attaches last; selection must still pick the sooner ball.
	var straggler: Ball = _spawn_ball(Vector2(-100.0, 100.0), Vector2(80.0, 0.0))
	tracker.attach(straggler)
	assert_eq(_controller.ball, straggler, "precondition: signal-bound ball is the straggler")
	_run_frames(5)

	assert_eq(_controller.ball, sooner_ball, "partner switches to the newly sooner ball")
	assert_lt(_paddle.velocity.y, 0.0, "partner now tracks the sooner ball above center")
