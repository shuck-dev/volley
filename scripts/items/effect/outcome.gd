class_name Outcome
extends Resource

@export var level_scaling := 1.0


func apply(_effect_state: EffectState, _source_key: String, _level: int) -> void:
	assert(false, "Outcome.apply() must be overridden by subclass")


func describe() -> String:
	return ""


func scaled_value(base_value: float, level: int) -> float:
	return base_value * (1.0 + level_scaling * (level - 1))
