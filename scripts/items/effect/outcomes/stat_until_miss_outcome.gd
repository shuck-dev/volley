class_name StatUntilMissOutcome
extends Outcome

@export var stat_key: StringName
@export var operation: StringName = &"add"
@export var value: float
@export var range_stat_key: StringName
## Maximum total value that can accumulate from repeated triggers. 0 means no cap.
@export var max_value: float = 0.0


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var add_amount: float = scaled_value(value, level)

	var cap: float = scaled_value(max_value, level) if max_value > 0.0 else 0.0
	if cap > 0.0:
		var current_total: float = effect_state.get_temporary_total(stat_key, source_key)
		var remaining: float = cap - current_total
		if remaining <= 0.0:
			return
		add_amount = minf(add_amount, remaining)

	var modifier := StatModifier.new()
	modifier.source_key = source_key
	modifier.stat_key = stat_key
	modifier.operation = StatModifier.OPERATION_BY_NAME[operation]
	modifier.value = add_amount
	modifier.temporary = true
	if range_stat_key:
		modifier.range_stat_key = range_stat_key
	effect_state.add_modifier(modifier)


func describe() -> String:
	var prefix := "+" if operation == &"add" and value > 0 else ""
	if range_stat_key:
		return "%s%.0f%% of %s to %s (until miss)" % [prefix, value * 100, range_stat_key, stat_key]
	return "%s%s %s (until miss)" % [prefix, value, stat_key]
