extends GutTest

var _machine: RefCounted


func before_each() -> void:
	_machine = load("res://scripts/core/paddle_animation_state_machine.gd").new()


# Pure state-resolution tests (from test_paddle_animation_state.gd)


func test_swing_pending_grounded_overrides_ready() -> void:
	_machine.on_hit(true, 0.0)
	assert_eq(_machine.get_state(), &"swing_grounded")


func test_swing_pending_flying_overrides_motion() -> void:
	_machine.on_hit(false, -100.0)
	assert_eq(_machine.get_state(), &"swing_flying")


func test_grounded_still_is_ready_grounded() -> void:
	_machine.update(true, 0.0)
	assert_eq(_machine.get_state(), &"ready_grounded")


func test_grounded_with_motion_still_ready_grounded() -> void:
	_machine.update(true, 100.0)
	assert_eq(_machine.get_state(), &"ready_grounded")


func test_flying_upward_is_flying_up() -> void:
	_machine.update(false, -100.0)
	assert_eq(_machine.get_state(), &"flying_up")


func test_flying_downward_is_flying_down() -> void:
	_machine.update(false, 100.0)
	assert_eq(_machine.get_state(), &"flying_down")


func test_flying_still_is_ready_flying() -> void:
	_machine.update(false, 0.0)
	assert_eq(_machine.get_state(), &"ready_flying")


func test_nearly_zero_motion_is_ready_flying() -> void:
	_machine.update(false, 0.000001)
	assert_eq(_machine.get_state(), &"ready_flying")


# Swing lifecycle tests (from test_paddle_animation_fsm.gd)


func test_hit_while_grounded_enters_swing_grounded() -> void:
	_machine.on_hit(true, 0.0)
	assert_eq(_machine.get_state(), &"swing_grounded")


func test_hit_while_flying_enters_swing_flying() -> void:
	_machine.on_hit(false, 100.0)
	assert_eq(_machine.get_state(), &"swing_flying")


func test_swing_finished_while_grounded_returns_to_ready_grounded() -> void:
	_machine.on_hit(true, 0.0)
	assert_eq(_machine.get_state(), &"swing_grounded")
	_machine.on_swing_finished(true, 0.0)
	assert_eq(_machine.get_state(), &"ready_grounded")


func test_swing_finished_while_flying_returns_to_live_flying_state() -> void:
	_machine.update(false, 100.0)
	_machine.on_hit(false, 100.0)
	assert_eq(_machine.get_state(), &"swing_flying")
	_machine.on_swing_finished(false, 100.0)
	assert_eq(_machine.get_state(), &"flying_down", "resumes the live flying state after swing")


# State change signal tests


func test_state_changed_signal_does_not_emit_when_state_unchanged() -> void:
	_machine.update(true, 0.0)

	var signal_fired := false
	_machine.state_changed.connect(func(_state: StringName) -> void: signal_fired = true)

	_machine.update(true, 0.0)
	assert_false(signal_fired, "state_changed should not emit for unchanged state")
