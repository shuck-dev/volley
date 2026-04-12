class_name PartnerDefinition
extends Resource

# preload workaround for autoload class_name ordering (godotengine/godot#75582)
@warning_ignore("shadowed_global_identifier")
const Effect = preload("res://scripts/items/effect/effect.gd")

@export var key: StringName
@export var display_name: String
@export var unlock_threshold: int
@export var unlock_cost: int
@export var effects: Array[Effect]
