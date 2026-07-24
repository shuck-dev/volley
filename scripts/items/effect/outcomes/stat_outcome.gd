class_name StatOutcome
extends Outcome

@export var stat_key: StringName
@export var operation: StringName = &"add"
@export var value: float
@export var range_stat_key: StringName


func apply(effect_state: EffectState, source_key: String, level: int, instanced: bool) -> void:
	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = stat_key
	modifier.operation = StatModifier.OPERATION_BY_NAME[operation]
	modifier.value = scaled_value(value, level)
	modifier.instanced = instanced
	if range_stat_key:
		modifier.range_stat_key = range_stat_key
	effect_state.add_modifier(modifier)


func describe() -> String:
	var positive_prefix := "+" if value > 0 else ""
	match operation:
		&"percentage":
			return "%s%.0f%% %s" % [positive_prefix, value * 100, stat_key]
		&"add":
			if range_stat_key:
				return (
					"%s%.0f%% of %s to %s"
					% [positive_prefix, value * 100, range_stat_key, stat_key]
				)
			return "%s%s %s" % [positive_prefix, value, stat_key]
		_:
			if range_stat_key:
				return "%.0f%% of %s to %s" % [value * 100, range_stat_key, stat_key]
			return "%s %s" % [value, stat_key]
