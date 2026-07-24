# gdlint:ignore = max-public-methods
extends GutTest

var _state: EffectState


func before_each() -> void:
	_state = EffectState.new()
	_state.register_base_values({&"speed": 100.0, &"size": 50.0})


func _make_modifier(
	source: String, stat: StringName, operation: StatModifier.Operation, value: float
) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.source_key = source
	modifier.stat_key = stat
	modifier.operation = operation
	modifier.value = value
	return modifier


# --- get_stat ---
func test_get_stat_returns_base_value_when_no_modifiers() -> void:
	assert_eq(_state.get_stat(&"speed"), 100.0)


func test_add_modifier_increases_stat() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	assert_eq(_state.get_stat(&"speed"), 150.0)


func test_multiple_add_modifiers_stack() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 20.0))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.ADD, 30.0))
	assert_eq(_state.get_stat(&"speed"), 150.0)


func test_percentage_modifier_applies_offset_from_one() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	# 100 * (1.0 + 0.5) = 150
	assert_eq(_state.get_stat(&"speed"), 150.0)


func test_multiple_percentage_modifiers_sum_additively() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.PERCENTAGE, -0.2))
	# 100 * (1.0 + 0.5 + -0.2) = 130, not 100 * 1.5 * 0.8 = 120
	assert_eq(_state.get_stat(&"speed"), 130.0)


func test_percentage_applies_after_add() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	# (100 + 50) * 1.5 = 225
	assert_eq(_state.get_stat(&"speed"), 225.0)


func test_modifier_for_one_stat_does_not_affect_another() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	assert_eq(_state.get_stat(&"size"), 50.0)


# --- remove_modifiers_by_source ---
func test_remove_modifiers_by_source_removes_that_sources_modifiers() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	_state.remove_modifiers_by_source("item_a")
	assert_eq(_state.get_stat(&"speed"), 100.0)


func test_remove_modifiers_by_source_keeps_other_sources() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 20.0))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.ADD, 30.0))
	_state.remove_modifiers_by_source("item_a")
	assert_eq(_state.get_stat(&"speed"), 130.0)


func test_remove_modifiers_by_source_removes_across_operations() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	_state.remove_modifiers_by_source("item_a")
	assert_eq(_state.get_stat(&"speed"), 100.0)


# --- shift range value invalidation ---
func test_add_modifier_refreshes_shift_range_value() -> void:
	var shift := _make_shift(&"speed", "osc_a", &"size")
	_state.add_shift(shift)
	_state.add_modifier(_make_modifier("item_a", &"size", StatModifier.Operation.ADD, 50.0))
	# Base size is now 100, shift's cached range_value should match.
	assert_eq(_state.get_base_stat(&"size"), 100.0)
	assert_almost_eq(shift._range_value, 100.0, 0.0001)


func test_remove_modifiers_by_source_refreshes_shift_range_value() -> void:
	var shift := _make_shift(&"speed", "osc_a", &"size")
	_state.add_shift(shift)
	_state.add_modifier(_make_modifier("item_a", &"size", StatModifier.Operation.ADD, 50.0))
	_state.remove_modifiers_by_source("item_a")
	assert_almost_eq(shift._range_value, 50.0, 0.0001)


func test_clear_temporary_modifiers_refreshes_shift_range_value() -> void:
	var shift := _make_shift(&"speed", "osc_a", &"size")
	_state.add_shift(shift)
	var modifier := _make_modifier("item_a", &"size", StatModifier.Operation.ADD, 50.0)
	modifier.temporary = true
	_state.add_modifier(modifier)
	_state.clear_temporary_modifiers()
	assert_almost_eq(shift._range_value, 50.0, 0.0001)


func test_register_base_values_refreshes_shift_range_value() -> void:
	var shift := _make_shift(&"speed", "osc_a", &"size")
	_state.add_shift(shift)
	_state.register_base_values({&"size": 200.0})
	assert_almost_eq(shift._range_value, 200.0, 0.0001)


func test_get_stat_with_instance_key_only_reflects_that_instances_shift() -> void:
	var shift_a := _make_shift(&"speed", "ball_a", &"")
	var shift_b := _make_shift(&"speed", "ball_b", &"")
	shift_a.instanced = true
	shift_b.instanced = true
	shift_a._mode = StatShift.Mode.DOUBLE
	shift_b._mode = StatShift.Mode.HALF
	_state.add_shift(shift_a)
	_state.add_shift(shift_b)

	assert_eq(_state.get_stat(&"speed", "ball_a"), 101.0)
	assert_eq(_state.get_stat(&"speed", "ball_b"), 99.5)


func _make_shift(stat: StringName, source: String, range_key: StringName) -> StatShift:
	var shift := StatShift.new()
	shift.stat_key = stat
	shift.source_key = source
	shift.range_stat_key = range_key
	shift.min_interval = 1.0
	shift.max_interval = 1.0
	shift.start()
	return shift


# --- states ---
func test_state_is_not_active_before_being_set() -> void:
	assert_false(_state.is_state_active(&"on_fire"))


func test_state_is_active_after_being_set() -> void:
	_state.set_state(&"on_fire", "item_a")
	assert_true(_state.is_state_active(&"on_fire"))


func test_clear_state_deactivates_state() -> void:
	_state.set_state(&"on_fire", "item_a")
	_state.clear_state(&"on_fire")
	assert_false(_state.is_state_active(&"on_fire"))


func test_clearing_one_state_does_not_affect_another() -> void:
	_state.set_state(&"on_fire", "item_a")
	_state.set_state(&"frozen", "item_b")
	_state.clear_state(&"on_fire")
	assert_true(_state.is_state_active(&"frozen"))
