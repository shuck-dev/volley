extends GutTest

# Tests for PaddleAIMath: pure math functions for prediction and noise.

const BOUND_Y := -351.6
const GRAVITY := 980.0


# --- predict_intercept: below bound, no gravity ---
func test_predicts_ball_y_when_travelling_straight() -> void:
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(100.0, 200.0), Vector2(-200.0, 0.0), 0.0, BOUND_Y, GRAVITY
	)
	assert_almost_eq(intercept, 200.0, 0.1)


func test_predicts_ball_y_with_vertical_component_below_bound() -> void:
	# Both start and end below bound (vy small enough to stay below over 1s).
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, 0.0), Vector2(-200.0, 100.0), 0.0, BOUND_Y, GRAVITY
	)
	assert_almost_eq(intercept, 100.0, 1.0)


# --- predict_intercept: above bound, gravity acts ---
func test_gravity_pulls_ball_back_when_above_bound() -> void:
	# Start above the bound moving up: gravity decelerates vy and pulls it back.
	var no_gravity: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, BOUND_Y - 100.0), Vector2(-200.0, -200.0), 0.0, BOUND_Y, 0.0
	)
	var with_gravity: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, BOUND_Y - 100.0), Vector2(-200.0, -200.0), 0.0, BOUND_Y, GRAVITY
	)
	# Under gravity, ball comes back down; predicted y is larger (further down screen) than under no gravity.
	assert_gt(with_gravity, no_gravity)


func test_prediction_clamped_within_arena() -> void:
	var arena_half: float = GameRules.base.arena_height / 2.0
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, 0.0), Vector2(-1.0, 9999.0), 0.0, BOUND_Y, GRAVITY
	)
	assert_true(
		intercept >= -arena_half and intercept <= arena_half,
		"prediction should always be within arena bounds, got %.1f" % intercept,
	)


func test_returns_ball_y_when_barely_moving_horizontally() -> void:
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(100.0, 300.0), Vector2(0.5, 200.0), 0.0, BOUND_Y, GRAVITY
	)
	assert_almost_eq(intercept, 300.0, 0.1)


# --- random_offset ---
func test_noise_zero_returns_zero() -> void:
	assert_eq(PaddleAIMath.random_offset(0.0), 0.0)


func test_noise_produces_nonzero_values() -> void:
	var nonzero_count := 0
	for _sample_index in range(100):
		if abs(PaddleAIMath.random_offset(20.0)) > 0.1:
			nonzero_count += 1
	assert_gt(nonzero_count, 50, "most noise samples should be nonzero")
