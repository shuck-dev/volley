class_name EffectState
extends RefCounted

var _base_values: Dictionary[StringName, float] = {}
var _add_modifiers: Array[StatModifier] = []
var _percentage_modifiers: Array[StatModifier] = []
var _active_states: Dictionary[StringName, String] = {}
var _shifts: ShiftRepository = ShiftRepository.new()
var _resolving_keys: Array[StringName] = []


func get_stat(key: StringName, instance_key: String = "") -> float:
	assert(_base_values.has(key), "EffectState: unregistered stat key: " + key)

	var result: float = _base_values[key]
	result += _shifts.sum_for(key, instance_key)
	result += _sum_modifiers(key, _add_modifiers, false, instance_key)
	result *= 1.0 + _sum_modifiers(key, _percentage_modifiers, false, instance_key)
	return result


func get_base_stat(key: StringName, instance_key: String = "") -> float:
	assert(_base_values.has(key), "EffectState: unregistered stat key: " + key)
	assert(
		key not in _resolving_keys,
		"EffectState: circular dependency resolving stat: " + key,
	)
	_resolving_keys.append(key)

	var result: float = _base_values[key]
	result += _shifts.sum_for(key, instance_key)
	result += _sum_modifiers(key, _add_modifiers, true, instance_key)
	result *= 1.0 + _sum_modifiers(key, _percentage_modifiers, true, instance_key)
	_resolving_keys.erase(key)
	return result


func get_percentage_offset(key: StringName, instance_key: String = "") -> float:
	return _sum_modifiers(key, _percentage_modifiers, false, instance_key)


## Sum of additive modifiers and shifted multipliers for a stat key, range-resolved.
func get_modifier(key: StringName, instance_key: String = "") -> float:
	return (
		_shifts.sum_for(key, instance_key)
		+ _sum_modifiers(key, _add_modifiers, false, instance_key)
	)


## Same as `get_modifier` but excludes temporary (until-miss) modifiers.
func get_permanent_modifier(key: StringName, instance_key: String = "") -> float:
	return (
		_shifts.sum_for(key, instance_key) + _sum_modifiers(key, _add_modifiers, true, instance_key)
	)


func add_modifier(modifier: StatModifier) -> void:
	_array_for_operation(modifier.operation).append(modifier)
	_shifts.refresh_range_values(get_base_stat)


func remove_modifiers_by_source(source_key: String) -> void:
	_add_modifiers = _add_modifiers.filter(_exclude_source.bind(source_key))
	_percentage_modifiers = _percentage_modifiers.filter(_exclude_source.bind(source_key))
	_shifts.remove_by_source(source_key)
	_shifts.refresh_range_values(get_base_stat)


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
	_shifts.refresh_range_values(get_base_stat)


func register_base_values(values: Dictionary) -> void:
	for key in values:
		_base_values[key] = values[key]
	_shifts.refresh_range_values(get_base_stat)


func add_shift(shift: StatShift) -> void:
	_shifts.add(shift)
	if shift.range_stat_key:
		shift.set_range_value(get_base_stat(shift.range_stat_key))


## Shifts registered under `source_key` (e.g. a ball wiring a cue to its own shift).
func get_shifts(source_key: String) -> Array[StatShift]:
	return _shifts.for_source(source_key)


func process_frame(delta: float) -> void:
	_shifts.process_frame(delta)


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
	return _add_modifiers


func _sum_modifiers(
	key: StringName,
	modifiers: Array[StatModifier],
	exclude_temporary: bool,
	instance_key: String = ""
) -> float:
	var total := 0.0
	for modifier in modifiers:
		if modifier.stat_key != key:
			continue
		if exclude_temporary and modifier.temporary:
			continue
		if instance_key and modifier.instanced and modifier.source_key != instance_key:
			continue
		total += _resolve_value(modifier)
	return total


func _resolve_value(modifier: StatModifier) -> float:
	if modifier.range_stat_key:
		return modifier.value * get_base_stat(modifier.range_stat_key)
	return modifier.value


func _exclude_source(modifier: StatModifier, source_key: String) -> bool:
	return modifier.source_key != source_key
