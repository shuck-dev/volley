extends GutTest

# Tests for PaddleAnimationController's swing-anticipation trigger and speed-scale threading.

var _controller: PaddleAnimationController
var _emitted_speed_scale: float = -1.0


func before_each() -> void:
	_controller = load("res://scripts/core/paddle_animation_controller.gd").new(0.0)
	_emitted_speed_scale = -1.0
	_controller.state_changed.connect(_on_state_changed)


func _on_state_changed(_state: StringName, speed_scale: float) -> void:
	_emitted_speed_scale = speed_scale


func test_anticipated_hit_emits_the_given_speed_scale() -> void:
	_controller.on_anticipated_hit(true, 2.5)

	assert_eq(_emitted_speed_scale, 2.5)


func test_on_hit_emits_the_default_speed_scale() -> void:
	_controller.on_hit(true, false)

	assert_eq(_emitted_speed_scale, PaddleAnimationController.DEFAULT_SPEED_SCALE)


func test_on_swing_finished_emits_the_default_speed_scale_after_an_anticipated_swing() -> void:
	_controller.on_anticipated_hit(true, 2.0)

	_controller.on_swing_finished(true, false)

	assert_eq(_emitted_speed_scale, PaddleAnimationController.DEFAULT_SPEED_SCALE)


func test_zone_entered_starts_the_swing_with_a_computed_speed_scale() -> void:
	_controller.on_zone_entered(-580.0, -200.0, -700.0, true)

	assert_eq(_controller.get_state(), &"swing_grounded")
	assert_almost_eq(_emitted_speed_scale, 1.0, 0.001)


func test_zone_entered_leaves_the_paddle_ready_for_a_stationary_ball() -> void:
	_controller.tick(0.0, true, false)

	_controller.on_zone_entered(-580.0, 0.5, -700.0, true)

	assert_eq(_controller.get_state(), &"ready_grounded")


func test_zone_entered_keeps_the_pending_swings_scale_when_already_swinging() -> void:
	_controller.on_anticipated_hit(true, 1.0)

	_controller.on_zone_entered(-580.0, -200.0, -700.0, true)

	assert_eq(_emitted_speed_scale, 1.0)
