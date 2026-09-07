class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)


func toggle() -> void:
	set_enabled(not _enabled)
	paddle.input_blocked = _enabled
	autoplay_toggled.emit(_enabled)


## Silent no-op when no ball is bound; a dead-ball key press must not lock out manual control.
func set_enabled(value: bool) -> void:
	if value and ball == null:
		return
	_enabled = value

	if not _enabled:
		paddle.wants_low_stance = false


func _court_side_sign() -> float:
	return -1.0


func _get_paddle_speed() -> float:
	return paddle.get_speed()
