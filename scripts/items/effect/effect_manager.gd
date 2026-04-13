class_name EffectManager
extends Node

var _effect_state: EffectState = EffectState.new()
var _event_effects: Array[Dictionary] = []


func _ready() -> void:
	_effect_state.register_base_values(GameRules.base_stats)


func get_stat(key: StringName) -> float:
	return _effect_state.get_stat(key)


func get_base_stat(key: StringName) -> float:
	return _effect_state.get_base_stat(key)


func get_percentage_offset(key: StringName) -> float:
	return _effect_state.get_percentage_offset(key)


func is_game_state_active(state: StringName) -> bool:
	return _effect_state.is_state_active(state)


func process_event(event_type: StringName) -> Array[StringName]:
	var game_actions: Array[StringName] = []
	for registered in _event_effects:
		var effect: Effect = registered.effect
		if effect.trigger.type == event_type:
			_collect_game_actions(effect, game_actions)
			_apply_effect(effect, registered.source_key, registered.level)

	if event_type == &"on_miss":
		_effect_state.clear_temporary_modifiers()

	return game_actions


func process_frame(delta: float) -> void:
	_effect_state.process_frame(delta)


func unregister_source(source: Resource) -> void:
	assert(source.has_method("get_key"), "Effect source must implement get_key()")
	_clear_source(source.get_key())


func register_source(source: Resource, level: int) -> void:
	assert(source.has_method("get_key"), "Effect source must implement get_key()")
	assert(
		source.has_method("get_effects_for_level"),
		"Effect source must implement get_effects_for_level()"
	)
	var source_key: String = source.get_key()
	_clear_source(source_key)
	for effect in source.get_effects_for_level(level):
		if effect.trigger.type == &"always":
			_apply_effect(effect, source_key, level)
		else:
			assert(
				not _has_temporary_outcome_on_miss(effect),
				"%s: on_miss + temporary modifier will be immediately cleared" % source_key,
			)
			var entry := {"effect": effect, "source_key": source_key, "level": level}
			_event_effects.append(entry)


func _collect_game_actions(effect: Effect, actions: Array[StringName]) -> void:
	for outcome in effect.outcomes:
		if outcome is GameActionOutcome:
			actions.append(outcome.action_key)


func _has_temporary_outcome_on_miss(effect: Effect) -> bool:
	if effect.trigger.type != &"on_miss":
		return false
	for outcome in effect.outcomes:
		if outcome is StatUntilMissOutcome:
			return true
	return false


func _clear_source(source_key: String) -> void:
	_effect_state.remove_modifiers_by_source(source_key)
	_event_effects = _event_effects.filter(
		func(registered: Dictionary) -> bool: return registered.source_key != source_key
	)


func _apply_effect(effect: Effect, source_key: String, level: int) -> void:
	for outcome in effect.outcomes:
		outcome.apply(_effect_state, source_key, level)
