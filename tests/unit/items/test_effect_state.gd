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


func test_multiply_modifier_scales_stat() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.MULTIPLY, 2.0))
	assert_eq(_state.get_stat(&"speed"), 200.0)


func test_multiple_multiply_modifiers_stack() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.MULTIPLY, 2.0))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.MULTIPLY, 3.0))
	assert_eq(_state.get_stat(&"speed"), 600.0)


func test_add_is_applied_before_multiply() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.MULTIPLY, 2.0))
	# (100 + 50) * 2 = 300, not (100 * 2) + 50 = 250
	assert_eq(_state.get_stat(&"speed"), 300.0)


func test_percentage_modifier_applies_offset_from_one() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	# 100 * (1.0 + 0.5) = 150
	assert_eq(_state.get_stat(&"speed"), 150.0)


func test_multiple_percentage_modifiers_sum_additively() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.PERCENTAGE, -0.2))
	# 100 * (1.0 + 0.5 + -0.2) = 130, not 100 * 1.5 * 0.8 = 120
	assert_eq(_state.get_stat(&"speed"), 130.0)


func test_percentage_applies_after_add_before_multiply() -> void:
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.ADD, 50.0))
	_state.add_modifier(_make_modifier("item_b", &"speed", StatModifier.Operation.PERCENTAGE, 0.5))
	_state.add_modifier(_make_modifier("item_c", &"speed", StatModifier.Operation.MULTIPLY, 2.0))
	# ((100 + 50) * 1.5) * 2 = 450
	assert_eq(_state.get_stat(&"speed"), 450.0)


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
	_state.add_modifier(_make_modifier("item_a", &"speed", StatModifier.Operation.MULTIPLY, 2.0))
	_state.remove_modifiers_by_source("item_a")
	assert_eq(_state.get_stat(&"speed"), 100.0)


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
