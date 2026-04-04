class_name StatOscillation
extends RefCounted

## Layered sine waves at co-prime frequencies for organic, non-repeating oscillation.
const PRIMARY_FREQUENCY := 1.7
const SECONDARY_FREQUENCY := 3.1
const TERTIARY_FREQUENCY := 5.3
const PRIMARY_WEIGHT := 0.6
const SECONDARY_WEIGHT := 0.3
const TERTIARY_WEIGHT := 0.1

var source_key: String
var stat_key: StringName
var amplitude: float
var range_stat_key: StringName
var _time := 0.0


func advance(delta: float) -> void:
	_time += delta


func get_offset(effect_state: EffectState) -> float:
	var wave: float = (
		sin(_time * PRIMARY_FREQUENCY) * PRIMARY_WEIGHT
		+ sin(_time * SECONDARY_FREQUENCY) * SECONDARY_WEIGHT
		+ sin(_time * TERTIARY_FREQUENCY) * TERTIARY_WEIGHT
	)
	return wave * amplitude * effect_state.get_permanent_stat(range_stat_key)
