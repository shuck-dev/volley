class_name PartnerPaddle
extends Paddle

@export var controller: PartnerAIController


func set_ball(value: RigidBody2D) -> void:
	controller.enable_with_ball(value)
