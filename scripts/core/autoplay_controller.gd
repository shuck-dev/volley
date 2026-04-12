class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)


func toggle() -> void:
	set_enabled(!_enabled)
	paddle.set_physics_process(!_enabled)
	autoplay_toggled.emit(_enabled)


func _ball_approaching() -> bool:
	return ball.linear_velocity.x < 0.0 and ball.position.x > paddle.position.x


func _is_ball_behind() -> bool:
	return ball.position.x < paddle.position.x


func _get_paddle_speed() -> float:
	return paddle.get_speed()
