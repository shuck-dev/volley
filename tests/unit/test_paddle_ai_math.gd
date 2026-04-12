extends GutTest

# Tests for PaddleAIMath: pure math functions for prediction and noise.


# --- predict_intercept: straight line ---
func test_predicts_ball_y_when_travelling_straight() -> void:
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(100.0, 200.0), Vector2(-200.0, 0.0), 0.0
	)
	assert_almost_eq(intercept, 200.0, 0.1)


func test_predicts_ball_y_with_vertical_component() -> void:
	# time = 200/200 = 1s, y = 0 + 100*1 = 100
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, 0.0), Vector2(-200.0, 100.0), 0.0
	)
	assert_almost_eq(intercept, 100.0, 0.1)


# --- predict_intercept: wall reflection ---
func test_reflects_off_bottom_wall() -> void:
	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	# time = 200/200 = 1s, projected y = (arena_half - 50) + 200 = arena_half + 150
	# reflected: arena_half - 150
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, arena_half - 50.0), Vector2(-200.0, 200.0), 0.0
	)
	var expected: float = arena_half - 150.0
	assert_almost_eq(intercept, expected, 1.0)


func test_reflects_off_top_wall() -> void:
	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	# time = 200/200 = 1s, projected y = (-arena_half + 50) - 200 = -arena_half - 150
	# reflected: -arena_half + 150
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, -arena_half + 50.0), Vector2(-200.0, -200.0), 0.0
	)
	var expected: float = -arena_half + 150.0
	assert_almost_eq(intercept, expected, 1.0)


func test_prediction_clamped_within_arena() -> void:
	var arena_half: float = GameRules.base_stats[&"arena_height"] / 2.0
	# Nearly vertical: many reflections
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(200.0, 0.0), Vector2(-1.0, 9999.0), 0.0
	)
	assert_true(
		intercept >= -arena_half and intercept <= arena_half,
		"prediction should always be within arena bounds, got %.1f" % intercept,
	)


func test_returns_ball_y_when_barely_moving_horizontally() -> void:
	var intercept: float = PaddleAIMath.predict_intercept(
		Vector2(100.0, 300.0), Vector2(0.5, 200.0), 0.0
	)
	assert_almost_eq(intercept, 300.0, 0.1)


# --- random_offset ---
func test_noise_zero_returns_zero() -> void:
	assert_eq(PaddleAIMath.random_offset(0.0), 0.0)


func test_noise_bounded_by_two_sigma() -> void:
	var max_observed := 0.0
	for _sample_index in range(1000):
		var sample: float = PaddleAIMath.random_offset(20.0)
		max_observed = maxf(max_observed, abs(sample))
	assert_true(
		max_observed <= 40.0,
		"noise should be clamped at 2x range, max observed: %.1f" % max_observed,
	)


func test_noise_produces_nonzero_values() -> void:
	var nonzero_count := 0
	for _sample_index in range(100):
		if abs(PaddleAIMath.random_offset(20.0)) > 0.1:
			nonzero_count += 1
	assert_gt(nonzero_count, 50, "most noise samples should be nonzero")
