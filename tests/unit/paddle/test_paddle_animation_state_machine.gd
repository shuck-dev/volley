extends GutTest

var _machine: RefCounted


func before_each() -> void:
	_machine = load("res://scripts/core/paddle_animation_state_machine.gd").new()


func test_ready_grounded_animation_fires_when_grounded() -> void:
	_machine.update(true, 0.0)
	assert_eq(_machine.get_state(), &"ready_grounded")


func test_ready_grounded_animation_fires_when_grounded_and_moving() -> void:
	_machine.update(true, 100.0)
	assert_eq(_machine.get_state(), &"ready_grounded")


func test_flying_up_animation_fires_when_moving_up() -> void:
	_machine.update(false, -100.0)
	assert_eq(_machine.get_state(), &"flying_up")


func test_flying_down_animation_fires_when_moving_down() -> void:
	_machine.update(false, 100.0)
	assert_eq(_machine.get_state(), &"flying_down")


func test_ready_flying_animation_fires_when_airborne_and_not_moving() -> void:
	_machine.update(false, 0.0)
	assert_eq(_machine.get_state(), &"ready_flying")


func test_ready_flying_animation_fires_when_motion_is_near_zero() -> void:
	_machine.update(false, 0.000001)
	assert_eq(_machine.get_state(), &"ready_flying")


func test_swing_grounded_animation_fires_when_hit_while_grounded() -> void:
	_machine.on_hit(true, 0.0)
	assert_eq(_machine.get_state(), &"swing_grounded")


func test_swing_flying_animation_fires_when_hit_while_airborne() -> void:
	_machine.on_hit(false, 100.0)
	assert_eq(_machine.get_state(), &"swing_flying")


func test_ready_grounded_animation_fires_when_swing_ends_while_grounded() -> void:
	_machine.on_hit(true, 0.0)
	assert_eq(_machine.get_state(), &"swing_grounded")
	_machine.on_swing_finished(true, 0.0)
	assert_eq(_machine.get_state(), &"ready_grounded")


func test_flying_down_animation_fires_when_swing_ends_while_moving_down() -> void:
	_machine.update(false, 100.0)
	_machine.on_hit(false, 100.0)
	assert_eq(_machine.get_state(), &"swing_flying")
	_machine.on_swing_finished(false, 100.0)
	assert_eq(
		_machine.get_state(), &"flying_down", "the live flying animation resumes after the swing"
	)
