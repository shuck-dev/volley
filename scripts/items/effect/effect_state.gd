class_name EffectState
extends RefCounted

var _base_values: Dictionary[StringName, float] = {}
var _add_modifiers: Array[StatModifier] = []
var _percentage_modifiers: Array[StatModifier] = []
var _multiply_modifiers: Array[StatModifier] = []
var _active_states: Dictionary[StringName, String] = {}
var _oscillations: Array[StatOscillation] = []
var _resolving_keys: Array[StringName] = []


func get_stat(key: StringName) -> float:
	assert(_base_values.has(key), "EffectState: unregistered stat key: " + key)

	var result: float = _base_values[key]
	result += _sum_oscillations(key)
	result += _sum_modifiers(key, _add_modifiers, false)
	result *= 1.0 + _sum_modifiers(key, _percentage_modifiers, false)
	result *= _product_modifiers(key, _multiply_modifiers, false)
	return result


func get_base_stat(key: StringName) -> float:
	assert(_base_values.has(key), "EffectState: unregistered stat key: " + key)
	assert(
		key not in _resolving_keys,
		"EffectState: circular dependency resolving stat: " + key,
	)
	_resolving_keys.append(key)

	var result: float = _base_values[key]
	result += _sum_oscillations(key)
	result += _sum_modifiers(key, _add_modifiers, true)
	result *= 1.0 + _sum_modifiers(key, _percentage_modifiers, true)
	result *= _product_modifiers(key, _multiply_modifiers, true)
	_resolving_keys.erase(key)
	return result


func get_percentage_offset(key: StringName) -> float:
	return _sum_modifiers(key, _percentage_modifiers, false)


func add_modifier(modifier: StatModifier) -> void:
	_array_for_operation(modifier.operation).append(modifier)


func remove_modifiers_by_source(source_key: String) -> void:
	_add_modifiers = _add_modifiers.filter(_exclude_source.bind(source_key))
	_percentage_modifiers = _percentage_modifiers.filter(_exclude_source.bind(source_key))
	_multiply_modifiers = _multiply_modifiers.filter(_exclude_source.bind(source_key))
	_oscillations = _oscillations.filter(
		func(oscillation: StatOscillation) -> bool: return oscillation.source_key != source_key
	)


func get_temporary_total(stat_key: StringName, source_key: String) -> float:
	var total := 0.0
	for modifier in _add_modifiers:
		if (
			modifier.temporary
			and modifier.stat_key == stat_key
			and modifier.source_key == source_key
		):
			total += modifier.value
	return total


func clear_temporary_modifiers() -> void:
	var keep_permanent := func(modifier: StatModifier) -> bool: return not modifier.temporary
	_add_modifiers = _add_modifiers.filter(keep_permanent)
	_percentage_modifiers = _percentage_modifiers.filter(keep_permanent)
	_multiply_modifiers = _multiply_modifiers.filter(keep_permanent)


func register_base_values(values: Dictionary) -> void:
	for key in values:
		_base_values[key] = values[key]


func add_oscillation(oscillation: StatOscillation) -> void:
	_oscillations.append(oscillation)


func process_frame(delta: float) -> void:
	for oscillation in _oscillations:
		oscillation.advance(delta)


func set_state(state: StringName, source_key: String) -> void:
	_active_states[state] = source_key


func clear_state(state: StringName) -> void:
	_active_states.erase(state)


func is_state_active(state: StringName) -> bool:
	return _active_states.has(state)


func _array_for_operation(operation: StatModifier.Operation) -> Array[StatModifier]:
	match operation:
		StatModifier.Operation.ADD:
			return _add_modifiers
		StatModifier.Operation.PERCENTAGE:
			return _percentage_modifiers
		StatModifier.Operation.MULTIPLY:
			return _multiply_modifiers
	return _add_modifiers


func _sum_oscillations(key: StringName) -> float:
	var total := 0.0
	for oscillation in _oscillations:
		if oscillation.stat_key == key:
			total += oscillation.get_offset(self)
	return total


func _sum_modifiers(
	key: StringName, modifiers: Array[StatModifier], exclude_temporary: bool
) -> float:
	var total := 0.0
	for modifier in modifiers:
		if modifier.stat_key == key and not (exclude_temporary and modifier.temporary):
			total += _resolve_value(modifier)
	return total


func _product_modifiers(
	key: StringName, modifiers: Array[StatModifier], exclude_temporary: bool
) -> float:
	var result := 1.0
	for modifier in modifiers:
		if modifier.stat_key == key and not (exclude_temporary and modifier.temporary):
			result *= _resolve_value(modifier)
	return result


func _resolve_value(modifier: StatModifier) -> float:
	if modifier.range_stat_key:
		return modifier.value * get_base_stat(modifier.range_stat_key)
	return modifier.value


func _exclude_source(modifier: StatModifier, source_key: String) -> bool:
	return modifier.source_key != source_key
