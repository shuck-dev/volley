extends GutTest

# Tests for PaddleAnimationController.on_anticipated_hit: the speed-scaled swing trigger
# fired by the paddle's swing-anticipation zone.

var _controller: PaddleAnimationController
var _emitted_speed_scale: float = -1.0


func before_each() -> void:
	_controller = load("res://scripts/core/paddle_animation_controller.gd").new(0.0)
	_emitted_speed_scale = -1.0
	_controller.state_changed.connect(_on_state_changed)


func _on_state_changed(_state: StringName, speed_scale: float) -> void:
	_emitted_speed_scale = speed_scale


func test_anticipated_hit_enters_swing_grounded_state() -> void:
	_controller.on_anticipated_hit(true, 2.0)

	assert_eq(_controller.get_state(), &"swing_grounded")


func test_anticipated_hit_enters_swing_flying_state() -> void:
	_controller.on_anticipated_hit(false, 2.0)

	assert_eq(_controller.get_state(), &"swing_flying")


func test_anticipated_hit_emits_the_given_speed_scale() -> void:
	_controller.on_anticipated_hit(true, 2.5)

	assert_eq(_emitted_speed_scale, 2.5)


func test_swing_pending_true_after_anticipated_hit() -> void:
	_controller.on_anticipated_hit(true, 1.0)

	assert_true(_controller.is_swing_pending())


func test_on_hit_emits_the_default_speed_scale() -> void:
	_controller.on_hit(true, false)

	assert_eq(_emitted_speed_scale, PaddleAnimationController.DEFAULT_SPEED_SCALE)


func test_on_swing_finished_emits_the_default_speed_scale_after_an_anticipated_swing() -> void:
	_controller.on_anticipated_hit(true, 2.0)

	_controller.on_swing_finished(true, false)

	assert_eq(_emitted_speed_scale, PaddleAnimationController.DEFAULT_SPEED_SCALE)


func test_resets_guard_when_the_ball_is_actually_hit() -> void:
	_controller.on_anticipated_hit(true, 1.0)
	assert_eq(_controller.get_state(), &"swing_grounded")

	_controller.on_hit(true, false)
	_controller.on_swing_finished(true, false)

	assert_eq(_controller.get_state(), &"ready_grounded")
