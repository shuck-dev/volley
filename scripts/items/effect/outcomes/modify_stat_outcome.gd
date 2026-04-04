class_name ModifyStatOutcome
extends Outcome

@export var stat_key: StringName
@export var operation: StringName = &"add"
@export var value: float


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = stat_key
	modifier.operation = StatModifier.OPERATION_BY_NAME[operation]
	modifier.value = scaled_value(value, level)
	effect_state.add_modifier(modifier)


func describe() -> String:
	var prefix := "+" if operation == &"add" and value > 0 else ""
	return "%s%s %s" % [prefix, value, stat_key]
