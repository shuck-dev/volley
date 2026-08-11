class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)


## Silent no-op when no ball is bound; set_enabled rejects the enable so dead-ball key presses don't crash.
func toggle() -> void:
	var desired: bool = not _enabled
	set_enabled(desired)
	paddle.input_blocked = _enabled
	autoplay_toggled.emit(_enabled)


func _ball_approaches(target: Ball) -> bool:
	return target.linear_velocity.x < 0.0 and target.position.x > paddle.position.x


func _get_paddle_speed() -> float:
	return paddle.get_speed()


func _lane_sign() -> float:
	return 1.0
