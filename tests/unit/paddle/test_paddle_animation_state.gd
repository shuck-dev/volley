extends GutTest

var _resolver: GDScript = load("res://scripts/core/paddle_animation_state.gd")


func test_swing_pending_grounded_overrides_ready() -> void:
	var state: StringName = _resolver.resolve_state(true, 0.0, true)
	assert_eq(state, &"swing_grounded")


func test_swing_pending_flying_overrides_motion() -> void:
	var state: StringName = _resolver.resolve_state(false, -100.0, true)
	assert_eq(state, &"swing_flying")


func test_grounded_still_is_ready_grounded() -> void:
	var state: StringName = _resolver.resolve_state(true, 0.0, false)
	assert_eq(state, &"ready_grounded")


func test_grounded_with_motion_still_ready_grounded() -> void:
	var state: StringName = _resolver.resolve_state(true, 100.0, false)
	assert_eq(state, &"ready_grounded")


func test_flying_upward_is_flying_up() -> void:
	var state: StringName = _resolver.resolve_state(false, -100.0, false)
	assert_eq(state, &"flying_up")


func test_flying_downward_is_flying_down() -> void:
	var state: StringName = _resolver.resolve_state(false, 100.0, false)
	assert_eq(state, &"flying_down")


func test_flying_still_is_ready_flying() -> void:
	var state: StringName = _resolver.resolve_state(false, 0.0, false)
	assert_eq(state, &"ready_flying")


func test_nearly_zero_motion_is_ready_flying() -> void:
	var state: StringName = _resolver.resolve_state(false, 0.000001, false)
	assert_eq(state, &"ready_flying")
