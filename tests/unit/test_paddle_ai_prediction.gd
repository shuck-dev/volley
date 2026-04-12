extends GutTest

# Tests for PaddleAIController prediction and noise logic.
# Uses AutoplayController as the concrete subclass since the base is abstract.

const PHYSICS_DELTA := 0.016

var _controller: AutoplayController
var _paddle: Paddle
var _ball: Ball
var _config: PaddleAIConfig


func before_each() -> void:
	_ball = load("res://tests/stubs/ball_stub.gd").new()
	_ball.position = Vector2.ZERO
	add_child_autofree(_ball)

	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	add_child_autofree(_paddle)

	_config = PaddleAIConfig.new()
	_config.reaction_delay_frames = 1
	_config.speed_scale = 1.0
	_config.noise = 0.0
	_config.velocity_smoothing = 1.0
	_config.snap_threshold = 0.0

	_controller = load("res://scripts/core/autoplay_controller.gd").new()
	_controller.paddle = _paddle
	_controller.ball = _ball
	_controller.config = _config
	add_child_autofree(_controller)


# --- prediction: straight line ---
func test_predicts_ball_y_when_travelling_straight() -> void:
	_ball.position = Vector2(100.0, 200.0)
	_ball.linear_velocity = Vector2(-200.0, 0.0)
	_paddle.position = Vector2(0.0, 0.0)

	var intercept: float = _controller._predict_intercept()

	assert_almost_eq(
		intercept, 200.0, 0.1, "straight horizontal ball should arrive at its current y"
	)


func test_predicts_ball_y_with_vertical_component() -> void:
	_ball.position = Vector2(200.0, 0.0)
	_ball.linear_velocity = Vector2(-200.0, 100.0)
	_paddle.position = Vector2(0.0, 0.0)

	var intercept: float = _controller._predict_intercept()

	# time = 200/200 = 1s, y = 0 + 100*1 = 100
	assert_almost_eq(intercept, 100.0, 0.1, "should project y forward by travel time")


# --- prediction: wall reflection ---
func test_predicts_reflection_off_bottom_wall() -> void:
	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	_ball.position = Vector2(200.0, arena_half - 50.0)
	_ball.linear_velocity = Vector2(-200.0, 200.0)
	_paddle.position = Vector2(0.0, 0.0)

	var intercept: float = _controller._predict_intercept()

	# time = 200/200 = 1s, projected y = (arena_half - 50) + 200 = arena_half + 150
	# overshoot = 150, reflected = arena_half - 150
	var expected: float = arena_half - 150.0
	assert_almost_eq(intercept, expected, 1.0, "should reflect off bottom wall")


func test_predicts_reflection_off_top_wall() -> void:
	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	_ball.position = Vector2(200.0, -arena_half + 50.0)
	_ball.linear_velocity = Vector2(-200.0, -200.0)
	_paddle.position = Vector2(0.0, 0.0)

	var intercept: float = _controller._predict_intercept()

	# time = 200/200 = 1s, projected y = (-arena_half + 50) - 200 = -arena_half - 150
	# overshoot = 150, reflected = -arena_half + 150
	var expected: float = -arena_half + 150.0
	assert_almost_eq(intercept, expected, 1.0, "should reflect off top wall")


func test_prediction_clamped_within_arena() -> void:
	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	_ball.position = Vector2(200.0, 0.0)
	# Nearly vertical: many reflections
	_ball.linear_velocity = Vector2(-1.0, 9999.0)
	_paddle.position = Vector2(0.0, 0.0)

	var intercept: float = _controller._predict_intercept()

	assert_true(
		intercept >= -arena_half and intercept <= arena_half,
		"prediction should always be within arena bounds, got %.1f" % intercept,
	)


func test_prediction_returns_ball_y_when_barely_moving_horizontally() -> void:
	_ball.position = Vector2(100.0, 300.0)
	_ball.linear_velocity = Vector2(0.5, 200.0)
	_paddle.position = Vector2(0.0, 0.0)

	var intercept: float = _controller._predict_intercept()

	assert_almost_eq(intercept, 300.0, 0.1, "near-zero x velocity should return current ball y")


# --- noise: clamped normal ---
func test_noise_zero_returns_zero() -> void:
	_config.noise = 0.0
	var sample: float = _controller._sample_noise()
	assert_eq(sample, 0.0, "noise=0 should produce no offset")


func test_noise_is_bounded_by_two_sigma() -> void:
	_config.noise = 20.0
	var max_observed := 0.0
	for _sample_index in range(1000):
		var sample: float = _controller._sample_noise()
		max_observed = maxf(max_observed, abs(sample))
	assert_true(
		max_observed <= 40.0,
		"noise should be clamped at 2x config value, max observed: %.1f" % max_observed,
	)


func test_noise_produces_nonzero_values() -> void:
	_config.noise = 20.0
	var nonzero_count := 0
	for _sample_index in range(100):
		if abs(_controller._sample_noise()) > 0.1:
			nonzero_count += 1
	assert_gt(nonzero_count, 50, "most noise samples should be nonzero")


# --- noise resampling ---
func test_noise_resamples_when_ball_changes_direction() -> void:
	_config.noise = 50.0
	_ball.linear_velocity = Vector2(-100.0, 0.0)
	_controller._maybe_resample_noise()
	var first_offset: float = _controller._noise_offset

	# Change direction
	_ball.linear_velocity = Vector2(100.0, 0.0)
	_controller._maybe_resample_noise()
	var second_offset: float = _controller._noise_offset

	# With noise=50, the chance of two identical samples is negligible
	assert_ne(first_offset, second_offset, "noise should resample on direction change")


func test_noise_does_not_resample_when_direction_unchanged() -> void:
	_config.noise = 50.0
	_ball.linear_velocity = Vector2(-100.0, 0.0)
	_controller._maybe_resample_noise()
	var first_offset: float = _controller._noise_offset

	_controller._maybe_resample_noise()
	var second_offset: float = _controller._noise_offset

	assert_eq(first_offset, second_offset, "noise should not resample when direction is the same")
