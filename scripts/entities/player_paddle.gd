class_name PlayerPaddle
extends Paddle


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	velocity = Vector2(0.0, direction * _paddle_speed)
	move_and_slide()
	position.x = _lane_x
