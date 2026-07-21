class_name RandomStatOutcome
extends Outcome

@export var stat_key: StringName
@export var operation: StringName = &"add"
@export var min_value: float
@export var max_value: float
@export var range_stat_key: StringName


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = stat_key
	modifier.operation = StatModifier.OPERATION_BY_NAME[operation]
	var raw := randf_range(min_value, max_value)
	modifier.value = scaled_value(raw, level)
	if range_stat_key:
		modifier.range_stat_key = range_stat_key
	effect_state.add_modifier(modifier)


func describe() -> String:
	var prefix := "+" if operation == &"add" else ""
	var range_desc := " [%s..%s]" % [min_value, max_value]
	if range_stat_key:
		return "%s%s%% of %s %s" % [prefix, range_desc, range_stat_key, stat_key]
	return "%s%s %s" % [prefix, range_desc, stat_key]
