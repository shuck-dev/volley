extends GutTest

# Tests for PaddleAnimationController's swing-anticipation speed-scale calculation.

var _controller: PaddleAnimationController


func before_each() -> void:
	_controller = load("res://scripts/core/paddle_animation_controller.gd").new(0.0)


func test_zone_entry_speed_scale_matches_the_ball_actual_contact_time() -> void:
	var speed_scale: float = _controller.compute_zone_entry_speed_scale(-580.0, -200.0, -700.0)

	assert_almost_eq(speed_scale, 1.0, 0.001)


func test_zone_entry_speed_scale_is_negative_for_a_stationary_ball() -> void:
	var speed_scale: float = _controller.compute_zone_entry_speed_scale(-580.0, 0.5, -700.0)

	assert_lt(speed_scale, 0.0)


func test_zone_entry_speed_scale_is_negative_while_a_swing_is_already_pending() -> void:
	_controller.on_anticipated_hit(true)

	var speed_scale: float = _controller.compute_zone_entry_speed_scale(-580.0, -200.0, -700.0)

	assert_lt(speed_scale, 0.0)
