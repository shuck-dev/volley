class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)

@export var timeout_controller: TimeoutController


func _ready() -> void:
	super._ready()
	if timeout_controller != null:
		timeout_controller.timeout_started.connect(_on_timeout_started)
		timeout_controller.timeout_ended.connect(_on_timeout_ended)


## Silent no-op when no ball is bound; set_enabled rejects the enable so dead-ball key presses don't crash.
func toggle() -> void:
	var desired: bool = not _enabled
	set_enabled(desired)
	# A running timeout owns the paddle; do not override its input_blocked state.
	var timeout_owns: bool = timeout_controller != null and timeout_controller.is_active()
	if not timeout_owns:
		paddle.input_blocked = _enabled
	autoplay_toggled.emit(_enabled)


## Force autoplay off without calling toggle(); the player re-enables manually after timeout.
func _on_timeout_started() -> void:
	if not _enabled:
		return
	set_enabled(false)
	autoplay_toggled.emit(false)


## Restore player input when timeout ends and autoplay is still off.
func _on_timeout_ended() -> void:
	if not _enabled:
		paddle.input_blocked = false


func _ball_approaches(target: Ball) -> bool:
	return target.linear_velocity.x < 0.0 and target.position.x > paddle.position.x


func _get_paddle_speed() -> float:
	return paddle.get_speed()
