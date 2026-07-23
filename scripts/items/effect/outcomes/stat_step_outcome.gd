class_name StatStepOutcome
extends Outcome

@export var stat_key: StringName
@export var range_stat_key: StringName
@export var min_interval: float = 2.0
@export var max_interval: float = 5.0


func apply(effect_state: EffectState, source_key: String, _level: int) -> void:
	var step := StatStep.new()
	step.source_key = source_key
	step.stat_key = stat_key
	step.range_stat_key = range_stat_key
	step.min_interval = min_interval
	step.max_interval = max_interval
	step.start()
	effect_state.add_step(step)


func describe() -> String:
	return "step %s half/normal/double every %.0f-%.0fs" % [stat_key, min_interval, max_interval]
