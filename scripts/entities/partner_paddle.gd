class_name PartnerPaddle
extends Paddle

@export var controller: PartnerAIController


# Partners use unmodified base values; ItemManager modifiers belong to the player paddle.
func _resolve(base: float, _key: StringName) -> float:
	return base


func _bind_stat_updates() -> void:
	pass


func set_ball(_value: RigidBody2D) -> void:
	pass
