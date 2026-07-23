class_name StatShiftOutcome
extends Outcome

@export var stat_key: StringName
@export var range_stat_key: StringName
@export var min_interval: float = 2.0
@export var max_interval: float = 5.0


func apply(effect_state: EffectState, source_key: String, _level: int) -> void:
	var shift := StatShift.new()
	shift.source_key = source_key
	shift.stat_key = stat_key
	shift.range_stat_key = range_stat_key
	shift.min_interval = min_interval
	shift.max_interval = max_interval
	shift.start()
	effect_state.add_shift(shift)


func describe() -> String:
	return "shift %s half/normal/double every %.0f-%.0fs" % [stat_key, min_interval, max_interval]
