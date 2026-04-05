class_name StatUntilMissOutcome
extends Outcome

@export var stat_key: StringName
@export var operation: StringName = &"add"
@export var value: float
@export var range_stat_key: StringName


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = stat_key
	modifier.operation = StatModifier.OPERATION_BY_NAME[operation]
	modifier.value = scaled_value(value, level)
	modifier.temporary = true
	if range_stat_key:
		modifier.range_stat_key = range_stat_key
	effect_state.add_modifier(modifier)


func describe() -> String:
	var prefix := "+" if operation == &"add" and value > 0 else ""
	if range_stat_key:
		return "%s%.0f%% of %s to %s (until miss)" % [prefix, value * 100, range_stat_key, stat_key]
	return "%s%s %s (until miss)" % [prefix, value, stat_key]


func _effective_value(effect_state: EffectState, level: int) -> float:
	var base_value: float = scaled_value(value, level)
	if range_stat_key:
		return base_value * effect_state.get_base_stat(range_stat_key)
	return base_value
