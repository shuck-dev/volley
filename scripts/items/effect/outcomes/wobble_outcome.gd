class_name WobbleOutcome
extends Outcome

@export var strength: float
@export var hit_interval: int = 1


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var counter_source := source_key + "/wobble_counter"
	var current: float = effect_state.get_temporary_total(&"wobble_hit_count", counter_source)
	var count := int(current)

	effect_state.remove_modifiers_by_source(counter_source)

	count += 1
	if count % hit_interval == 0:
		effect_state.remove_modifiers_by_source(source_key)
		var modifier := StatModifier.new()
		modifier.source_key = source_key
		modifier.stat_key = &"wobble_angle"
		modifier.operation = StatModifier.Operation.ADD
		modifier.value = scaled_value(strength, level)
		effect_state.add_modifier(modifier)
		count = 0

	var counter_mod := StatModifier.new()
	counter_mod.source_key = counter_source
	counter_mod.stat_key = &"wobble_hit_count"
	counter_mod.operation = StatModifier.Operation.ADD
	counter_mod.value = count
	counter_mod.temporary = true
	effect_state.add_modifier(counter_mod)


func describe() -> String:
	var prefix := "+" if strength > 0 else ""
	return "%s%.3f rad wobble (every %d hit)" % [prefix, strength, hit_interval]
