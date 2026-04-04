class_name Outcome
extends Resource

@export var type: StringName = &""
@export var parameters: Dictionary = {}
@export var level_scaling := 1.0


func scaled_value(key: StringName, level: int) -> float:
	var base_value: float = parameters[key]
	return base_value * (1.0 + level_scaling * (level - 1))
