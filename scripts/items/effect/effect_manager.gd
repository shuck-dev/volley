class_name EffectManager
extends Node

var _effect_state: EffectState = EffectState.new()
var _event_effects: Array[Dictionary] = []


func _ready() -> void:
	_effect_state.register_base_values(GameRules.BASE_CONFIG.to_dict())
	_effect_state.register_base_values(GameRules.PADDLE_CONFIG.to_dict())


func get_stat(key: StringName, instance_key: String = "") -> float:
	return _effect_state.get_stat(key, instance_key)


func get_base_stat(key: StringName, instance_key: String = "") -> float:
	return _effect_state.get_base_stat(key, instance_key)


func get_modifier(key: StringName, instance_key: String = "") -> float:
	return _effect_state.get_modifier(key, instance_key)


func get_permanent_modifier(key: StringName, instance_key: String = "") -> float:
	return _effect_state.get_permanent_modifier(key, instance_key)


func get_percentage_offset(key: StringName, instance_key: String = "") -> float:
	return _effect_state.get_percentage_offset(key, instance_key)


func is_game_state_active(state: StringName) -> bool:
	return _effect_state.is_state_active(state)


func get_shifts(instance_key: String) -> Array[StatShift]:
	return _effect_state.get_shifts(instance_key)


## `instance_key` scopes the dispatch to a single ball's registered effects; entries not
## registered as instance-scoped (partner/equipment sources) always fire regardless.
func process_event(event_type: StringName, instance_key: String = "") -> Array[StringName]:
	var game_actions: Array[StringName] = []
	for registered in _event_effects:
		var effect: Effect = registered.effect
		if effect.trigger.type != event_type:
			continue
		if instance_key and registered.instanced and registered.source_key != instance_key:
			continue
		_collect_game_actions(effect, game_actions)
		_apply_effect(effect, registered.source_key, registered.level)

	if event_type == &"on_miss":
		_effect_state.clear_temporary_modifiers()

	return game_actions


func process_frame(delta: float) -> void:
	_effect_state.process_frame(delta)


func unregister_source(source: Resource, source_key: String = "") -> void:
	assert(source.has_method("get_key"), "Effect source must implement get_key()")
	_clear_source(source_key if source_key else source.get_key())


func register_source(
	source: Resource, level: int, source_key: String = "", instanced: bool = false
) -> void:
	assert(source.has_method("get_key"), "Effect source must implement get_key()")
	assert(
		source.has_method("get_effects_for_level"),
		"Effect source must implement get_effects_for_level()"
	)
	var resolved_key: String = source_key if source_key else source.get_key()
	_clear_source(resolved_key)
	for effect in source.get_effects_for_level(level):
		if effect.trigger.type == &"always":
			_apply_effect(effect, resolved_key, level)
		else:
			assert(
				not _has_temporary_outcome_on_miss(effect),
				"%s: on_miss + temporary modifier will be immediately cleared" % resolved_key,
			)
			var entry := {
				"effect": effect, "source_key": resolved_key, "level": level, "instanced": instanced
			}
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
