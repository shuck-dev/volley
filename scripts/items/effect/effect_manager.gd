class_name EffectManager
extends Node

var _effect_state: EffectState = EffectState.new()


func _ready() -> void:
	_effect_state.register_base_values(GameRules.BASE_STATS)


func get_stat(key: StringName) -> float:
	return _effect_state.get_stat(key)


func is_game_state_active(state: StringName) -> bool:
	return _effect_state.is_state_active(state)


func unregister_source(source: ItemDefinition) -> void:
	_effect_state.remove_modifiers_by_source(source.get_key())


func register_source(source: ItemDefinition, level: int) -> void:
	_effect_state.remove_modifiers_by_source(source.get_key())
	for effect in source.get_effects_for_level(level):
		if effect.trigger.type == &"always":
			_apply_always_effect(effect, source.get_key(), level)


func _apply_always_effect(effect: Effect, source_key: String, level: int) -> void:
	for outcome in effect.outcomes:
		if outcome.type == &"modify_stat":
			var modifier := StatModifier.new()
			modifier.source_key = source_key
			modifier.stat_key = outcome.parameters[&"stat_key"]
			modifier.operation = StatModifier.OPERATION_BY_NAME[outcome.parameters[&"operation"]]
			modifier.value = outcome.parameters[&"value"] * level
			_effect_state.add_modifier(modifier)
