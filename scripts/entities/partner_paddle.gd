class_name PartnerPaddle
extends Paddle

@export var controller: PartnerAIController


func _get_stat(key: StringName) -> float:
	return GameRules.base_stats[key]


func _bind_stat_updates() -> void:
	pass


func set_ball(value: RigidBody2D) -> void:
	controller.enable_with_ball(value)
