extends RigidBody2D

var _start_x: float


func _ready() -> void:
	_start_x = position.x
	gravity_scale = 0.0
	linear_damp = 10.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	linear_velocity.y = direction * GameRules.PADDLE_SPEED
	position.x = _start_x  # Lock x position
