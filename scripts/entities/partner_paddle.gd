class_name PartnerPaddle
extends Paddle

@export var controller: PartnerAIController


# Partners use unmodified base values; BallManager modifiers belong to the player paddle.
func _bind_stat_updates() -> void:
	pass


func set_ball(_value: RigidBody2D) -> void:
	pass
