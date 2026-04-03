class_name EffectState
extends RefCounted

var _base_values: Dictionary[StringName, float] = {}
var _add_modifiers: Array[StatModifier] = []
var _multiply_modifiers: Array[StatModifier] = []
var _active_states: Dictionary[StringName, String] = {}


func get_stat(key: StringName) -> float:
	assert(_base_values.has(key), "EffectState: unregistered stat key: " + key)

	var result: float = _base_values[key]

	for modifier in _add_modifiers:
		if modifier.stat_key == key:
			result += modifier.value

	for modifier in _multiply_modifiers:
		if modifier.stat_key == key:
			result *= modifier.value

	return result


func add_modifier(modifier: StatModifier) -> void:
	match modifier.operation:
		StatModifier.Operation.ADD:
			_add_modifiers.append(modifier)
		StatModifier.Operation.MULTIPLY:
			_multiply_modifiers.append(modifier)


func remove_modifiers_by_source(source_key: String) -> void:
	_add_modifiers = _add_modifiers.filter(_exclude_source.bind(source_key))
	_multiply_modifiers = _multiply_modifiers.filter(_exclude_source.bind(source_key))


func register_base_values(values: Dictionary) -> void:
	for key in values:
		_base_values[key] = values[key]


func _exclude_source(modifier: StatModifier, source_key: String) -> bool:
	return modifier.source_key != source_key


func set_state(state: StringName, source_key: String) -> void:
	_active_states[state] = source_key


func clear_state(state: StringName) -> void:
	_active_states.erase(state)


func is_state_active(state: StringName) -> bool:
	return _active_states.has(state)
