extends GutTest

# Tests for PaddleSwingMath: pure math for the swing-anticipation speed scale.

const PaddleSwingMath: GDScript = preload("res://scripts/core/paddle_swing_math.gd")

const CONTACT_FRAME_INDEX := 3
const BASE_FPS := 5.0
const MAX_SPEED_SCALE := 3.0


func test_time_to_contact_computes_seconds_from_distance_and_speed() -> void:
	var seconds: float = PaddleSwingMath.time_to_contact(
		Vector2(-700.0, 0.0), Vector2(-580.0, 0.0), Vector2(-200.0, 0.0)
	)

	assert_almost_eq(seconds, 0.6, 0.001)


func test_time_to_contact_accounts_for_a_diagonal_approach() -> void:
	# 60-80-100 triangle: straight-line distance 100 at speed 100 gives 1.0s.
	var seconds: float = PaddleSwingMath.time_to_contact(
		Vector2(-700.0, 0.0), Vector2(-640.0, -80.0), Vector2(-60.0, 80.0)
	)

	assert_almost_eq(seconds, 1.0, 0.001)


func test_time_to_contact_returns_negative_one_when_ball_is_effectively_stationary() -> void:
	var seconds: float = PaddleSwingMath.time_to_contact(
		Vector2(-700.0, 0.0), Vector2(-580.0, 0.0), Vector2(0.5, 0.0)
	)

	assert_eq(seconds, -1.0)


func test_speed_scale_doubles_when_contact_time_is_half_the_natural_duration() -> void:
	var speed_scale: float = PaddleSwingMath.speed_scale_for_contact_time(
		0.3, CONTACT_FRAME_INDEX, BASE_FPS, MAX_SPEED_SCALE
	)

	assert_almost_eq(speed_scale, 2.0, 0.001)


func test_speed_scale_clamps_to_the_max_for_a_very_close_ball() -> void:
	var speed_scale: float = PaddleSwingMath.speed_scale_for_contact_time(
		0.01, CONTACT_FRAME_INDEX, BASE_FPS, MAX_SPEED_SCALE
	)

	assert_eq(speed_scale, MAX_SPEED_SCALE)
