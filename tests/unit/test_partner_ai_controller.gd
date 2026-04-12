extends GutTest

# Tests for PartnerAIController behaviour: tracking, drifting, dodging, speed cap.

const PHYSICS_DELTA := 0.016
const PADDLE_X := 300.0
const BALL_APPROACHING_PARTNER := Vector2(100.0, 0.0)
const BALL_MOVING_AWAY := Vector2(-100.0, 0.0)

var _controller: PartnerAIController
var _paddle: Paddle
var _ball: Ball
var _config: PaddleAIConfig


func before_each() -> void:
	_ball = load("res://tests/stubs/ball_stub.gd").new()
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
	_controller.enable_with_ball(_ball)


func _run_frames(count: int) -> void:
	for _frame in range(count):
		_controller._physics_process(PHYSICS_DELTA)


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


# --- dodging ---
func test_dodges_away_from_ball_when_ball_is_behind() -> void:
	_ball.position = Vector2(PADDLE_X + 50.0, 10.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	_paddle.position = Vector2(PADDLE_X, 0.0)

	_run_frames(5)
	assert_lt(
		_paddle.velocity.y,
		0.0,
		"should dodge away from ball (ball at y=10, dodge to negative edge)",
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


# --- speed cap ---
func test_speed_never_exceeds_configured_scale() -> void:
	_ball.position = Vector2(100.0, 9999.0)
	_ball.linear_velocity = BALL_APPROACHING_PARTNER
	var max_allowed: float = GameRules.base_stats[&"paddle_speed"] * _config.speed_scale
	_run_frames(50)
	for _check in range(50):
		_controller._physics_process(PHYSICS_DELTA)
		assert_true(
			abs(_paddle.velocity.y) <= max_allowed + 0.01,
			"velocity %.2f exceeded cap %.2f" % [abs(_paddle.velocity.y), max_allowed],
		)
