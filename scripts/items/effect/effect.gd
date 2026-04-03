class_name Effect
extends Resource

@export var trigger: Trigger
@export var conditions: Array[Condition] = []
@export var outcomes: Array[Outcome] = []
@export var min_active_level := 1
@export var max_active_level: Variant = null
