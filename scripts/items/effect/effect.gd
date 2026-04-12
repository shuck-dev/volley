class_name Effect
extends Resource

# preload workaround for autoload class_name ordering (godotengine/godot#75582)
@warning_ignore("shadowed_global_identifier")
const Trigger = preload("res://scripts/items/effect/trigger.gd")
@warning_ignore("shadowed_global_identifier")
const Condition = preload("res://scripts/items/effect/condition.gd")
@warning_ignore("shadowed_global_identifier")
const Outcome = preload("res://scripts/items/effect/outcome.gd")

@export var trigger: Trigger
@export var conditions: Array[Condition] = []
@export var outcomes: Array[Outcome] = []
@export var min_active_level := 1
@export var max_active_level: Variant = null
