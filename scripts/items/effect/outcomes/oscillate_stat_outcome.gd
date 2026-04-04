class_name OscillateStatOutcome
extends Outcome

@export var stat_key: StringName
@export var amplitude: float
@export var range_stat_key: StringName


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var oscillation := StatOscillation.new()
	oscillation.source_key = source_key
	oscillation.stat_key = stat_key
	oscillation.amplitude = scaled_value(amplitude, level)
	oscillation.range_stat_key = range_stat_key
	effect_state.add_oscillation(oscillation)


func describe() -> String:
	return "oscillate %s ±%.0f%% of %s" % [stat_key, amplitude * 100, range_stat_key]
