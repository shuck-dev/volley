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
## Canonical visual scale shared by shop, rack, held token, and live ball so the views read as one object (SH-261).
@export var token_scale: Vector2 = Vector2(1.5, 1.5)
## False for authored starter items that are owned-from-start and never appear in the shop catalog (SH-313).
@export var purchasable: bool = true
## SH-287: authored at-rest collision shape used for drop-target body projection.
## Ball items wire to their `CircleShape2D`; equipment items to their token bounds.
## Items whose at-rest representation is not a physics body may leave this null and the
## bounds check on the destination target alone decides acceptance.
@export var at_rest_shape: Shape2D


func get_effects_for_level(level: int) -> Array[Effect]:
	return effects.filter(_is_effect_active_at_level.bind(level))


func get_key() -> String:
	return key


func _is_effect_active_at_level(effect: Effect, level: int) -> bool:
	var effective_max: Variant = (
		effect.max_active_level if effect.max_active_level != null else max_level
	)
	return level >= effect.min_active_level and level <= effective_max
