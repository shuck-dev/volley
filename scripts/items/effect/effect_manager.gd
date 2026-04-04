class_name EffectManager
extends Node

var _effect_state: EffectState = EffectState.new()
var _event_effects: Array[Dictionary] = []


func _ready() -> void:
	_effect_state.register_base_values(GameRules.BASE_STATS)


func get_stat(key: StringName) -> float:
	return _effect_state.get_stat(key)


func is_game_state_active(state: StringName) -> bool:
	return _effect_state.is_state_active(state)


func process_event(event_type: StringName) -> void:
	for registered in _event_effects:
		var effect: Effect = registered.effect
		if effect.trigger.type == event_type:
			_apply_event_effect(effect, registered.source_key, registered.level)

	if event_type == &"on_miss":
		_effect_state.clear_until_miss_modifiers()


func process_frame(delta: float) -> void:
	_effect_state.process_frame(delta)


func unregister_source(source: ItemDefinition) -> void:
	var source_key: String = source.get_key()
	_effect_state.remove_modifiers_by_source(source_key)
	_event_effects = _event_effects.filter(
		func(registered: Dictionary) -> bool: return registered.source_key != source_key
	)


func register_source(source: ItemDefinition, level: int) -> void:
	var source_key: String = source.get_key()
	_effect_state.remove_modifiers_by_source(source_key)
	_event_effects = _event_effects.filter(
		func(registered: Dictionary) -> bool: return registered.source_key != source_key
	)
	for effect in source.get_effects_for_level(level):
		if effect.trigger.type == &"always":
			_apply_always_effect(effect, source_key, level)
		else:
			(
				_event_effects
				. append(
					{
						"effect": effect,
						"source_key": source_key,
						"level": level,
					}
				)
			)


func _apply_always_effect(effect: Effect, source_key: String, level: int) -> void:
	for outcome in effect.outcomes:
		if outcome.type == &"modify_stat":
			_add_permanent_modifier(outcome, source_key, level)
		elif outcome.type == &"oscillate_stat":
			(
				_effect_state
				. add_oscillation(
					source_key,
					outcome.parameters[&"stat_key"],
					outcome.scaled_value(&"wave_range", level),
				)
			)


func _apply_event_effect(effect: Effect, source_key: String, level: int) -> void:
	for outcome in effect.outcomes:
		if outcome.type == &"modify_stat_until_miss":
			var modifier := StatModifier.new()
			modifier.source_key = source_key
			modifier.stat_key = outcome.parameters[&"stat_key"]
			modifier.operation = StatModifier.OPERATION_BY_NAME[outcome.parameters[&"operation"]]
			modifier.value = outcome.scaled_value(&"value", level)
			_effect_state.add_until_miss_modifier(modifier)


func _add_permanent_modifier(outcome: Outcome, source_key: String, level: int) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = outcome.parameters[&"stat_key"]
	modifier.operation = StatModifier.OPERATION_BY_NAME[outcome.parameters[&"operation"]]
	modifier.value = outcome.scaled_value(&"value", level)
	_effect_state.add_modifier(modifier)
