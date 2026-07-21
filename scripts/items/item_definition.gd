class_name ItemDefinition
extends Resource

@export var key: String
@export var type: StringName = &""
## &"equipment" lives on the player; &"ball" lives on the court.
## Required; missing role fails the placement assertion (SH-414 oscillator-seam regression).
@export var role: StringName = &""
@export var display_name: String
@export var art: PackedScene
@export var descriptions: Array[String]
@export var base_cost: int
@export var cost_scaling := 1.6
@export var max_level := 3
@export var effects: Array[Effect]
## Standard visual scale shared by shop, rack, held token, and live ball so the views read as one object (SH-261).
@export var token_scale: Vector2 = Vector2(1.5, 1.5)
## False for authored starter items that are owned-from-start and never appear in the shop catalog (SH-313).
@export var purchasable: bool = true
## Authored at-rest shape for drop-target body projection; null falls back to bounds-only acceptance.
@export var at_rest_shape: Shape2D
## Soul cost for one upgrade in the workshop; player pays this per upgrade level.
@export var upgrade_cost: int = 50
## Per-character anchor for equipped visual; empty path falls back to character root.
@export var anchor_node_path: NodePath


func get_effects_for_level(level: int) -> Array[Effect]:
	return effects.filter(_is_effect_active_at_level.bind(level))


func get_key() -> String:
	return key


func _is_effect_active_at_level(effect: Effect, level: int) -> bool:
	var effective_max: Variant = (
		effect.max_active_level if effect.max_active_level != null else max_level
	)
	return level >= effect.min_active_level and level <= effective_max
