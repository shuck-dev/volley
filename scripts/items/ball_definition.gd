class_name BallDefinition
extends Resource

@export var key: String
@export var display_name: String
## The ball's own inherited scene (ball.tscn root script or subclass); BallReconciler spawns it
## live, and previews instantiate it frozen via Ball.enter_stored().
@export var scene: PackedScene
@export var base_cost: int
@export var cost_scaling := 1.6
@export var max_level := 3
@export var effects: Array[Effect]
## Falls back to the shared global default; give a ball its own resource instance to diverge.
@export var stats: BaseBallStats = load("res://resources/base_ball_stats.tres")


func get_effects_for_level(level: int) -> Array[Effect]:
	return effects.filter(_is_effect_active_at_level.bind(level))


func get_key() -> String:
	return key


func _is_effect_active_at_level(effect: Effect, level: int) -> bool:
	var effective_max: Variant = (
		effect.max_active_level if effect.max_active_level != null else max_level
	)
	return level >= effect.min_active_level and level <= effective_max
