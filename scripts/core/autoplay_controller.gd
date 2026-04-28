class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)


## Silent no-op when no ball is bound; set_enabled rejects the enable so dead-ball key presses don't crash.
func toggle() -> void:
	var desired: bool = not _enabled
	set_enabled(desired)
	# `paddle.set_physics_process` mirrors the actual enabled state so we
	# don't disable player input just because set_enabled refused.
	paddle.set_physics_process(not _enabled)
	autoplay_toggled.emit(_enabled)


func _ball_approaching() -> bool:
	return ball.linear_velocity.x < 0.0 and ball.position.x > paddle.position.x


func _is_ball_behind() -> bool:
	return ball.position.x < paddle.position.x


func _get_paddle_speed() -> float:
	return paddle.get_speed()
