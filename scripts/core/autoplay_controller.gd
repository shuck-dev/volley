class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)


func toggle() -> void:
	set_enabled(not _enabled)
	paddle.input_blocked = _enabled
	autoplay_toggled.emit(_enabled)


## Enables or disables AI for the paddle. _physics_process no-ops safely with no live ball yet.
func set_enabled(value: bool) -> void:
	_enabled = value


func _court_side_sign() -> float:
	return -1.0


func _get_paddle_speed() -> float:
	return paddle.get_speed()
