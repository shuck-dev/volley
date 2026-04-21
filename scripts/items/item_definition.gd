class_name ItemDefinition
extends Resource

@export var key: String
@export var type: StringName = &""
## Physical role of this item: determines its natural placement target.
## &"equipment" (default) lives on the player; &"ball" lives on the court.
@export var role: StringName = &"equipment"
@export var display_name: String
@export var art: PackedScene
@export var descriptions: Array[String]
@export var base_cost: int
@export var cost_scaling := 1.6
@export var max_level := 3
@export var effects: Array[Effect]


func get_effects_for_level(level: int) -> Array[Effect]:
	return effects.filter(_is_effect_active_at_level.bind(level))


func get_key() -> String:
	return key


func _is_effect_active_at_level(effect: Effect, level: int) -> bool:
	var effective_max: Variant = (
		effect.max_active_level if effect.max_active_level != null else max_level
	)
	return level >= effect.min_active_level and level <= effective_max
