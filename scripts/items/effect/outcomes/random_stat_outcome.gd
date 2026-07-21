class_name RandomStatOutcome
extends Outcome

@export var stat_key: StringName
@export var operation: StringName = &"add"
@export var min_value: float
@export var max_value: float
@export var range_stat_key: StringName


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var value := randf_range(scaled_value(min_value, level), scaled_value(max_value, level))
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = stat_key
	modifier.operation = StatModifier.OPERATION_BY_NAME[operation]
	modifier.value = value
	if range_stat_key:
		modifier.range_stat_key = range_stat_key
	effect_state.add_modifier(modifier)


func describe() -> String:
	return "random %s %.0f-%.0f" % [stat_key, min_value, max_value]
