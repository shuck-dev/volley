class_name OscillateStatOutcome
extends Outcome

@export var stat_key: StringName
@export var amplitude: float


func apply(effect_state: EffectState, source_key: String, level: int) -> void:
	var oscillation := StatOscillation.new()
	oscillation.source_key = source_key
	oscillation.stat_key = stat_key
	oscillation.amplitude = scaled_value(amplitude, level)
	effect_state.add_oscillation(oscillation)


func describe() -> String:
	return "oscillate %s ±%.1f" % [stat_key, amplitude]
