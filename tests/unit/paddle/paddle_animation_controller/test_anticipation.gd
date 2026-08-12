extends GutTest

# Tests for PaddleAnimationController's swing-anticipation speed-scale calculation.

var _controller: PaddleAnimationController


func before_each() -> void:
	_controller = load("res://scripts/core/paddle_animation_controller.gd").new(0.0)


func test_zone_entry_speed_scale_matches_the_ball_actual_contact_time() -> void:
	# Flying swing: contact_frames=3 at base_fps=5.0 -> 0.6s natural, matching this contact_time.
	var speed_scale: float = _controller.compute_zone_entry_speed_scale(
		Vector2(-580.0, 0.0), Vector2(-200.0, 0.0), Vector2(-700.0, 0.0), false
	)

	assert_almost_eq(speed_scale, 1.0, 0.001)


func test_zone_entry_speed_scale_is_negative_for_a_stationary_ball() -> void:
	var speed_scale: float = _controller.compute_zone_entry_speed_scale(
		Vector2(-580.0, 0.0), Vector2(0.5, 0.0), Vector2(-700.0, 0.0), false
	)

	assert_lt(speed_scale, 0.0)


func test_zone_entry_speed_scale_is_negative_while_a_swing_is_already_pending() -> void:
	_controller.start_swing(true)

	var speed_scale: float = _controller.compute_zone_entry_speed_scale(
		Vector2(-580.0, 0.0), Vector2(-200.0, 0.0), Vector2(-700.0, 0.0), true
	)

	assert_lt(speed_scale, 0.0)


func test_zone_entry_speed_scale_for_low_swing_stretches_its_one_frame_to_contact_time() -> void:
	# Crouching (swing_grounded_low): contact_frames=1 at base_fps=2.0 -> 0.5s natural.
	var speed_scale: float = _controller.compute_zone_entry_speed_scale(
		Vector2(-590.0, 0.0), Vector2(-20.0, 0.0), Vector2(-600.0, 0.0), true, true
	)

	assert_almost_eq(speed_scale, 1.0, 0.001)


func test_state_changed_forwards_the_state_machines_signal() -> void:
	var emitted_states: Array[StringName] = []
	_controller.state_changed.connect(func(state: StringName) -> void: emitted_states.append(state))

	_controller.start_swing(true)

	assert_eq(emitted_states, [&"swing_grounded"])
