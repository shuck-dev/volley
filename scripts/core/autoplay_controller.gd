class_name AutoplayController
extends PaddleAIController

signal autoplay_toggled(autoplay: bool)

@export var timeout_controller: TimeoutController


func _ready() -> void:
	super._ready()
	if timeout_controller != null:
		timeout_controller.timeout_started.connect(_on_timeout_started)


## Silent no-op when no ball is bound; set_enabled rejects the enable so dead-ball key presses don't crash.
func toggle() -> void:
	var desired: bool = not _enabled
	set_enabled(desired)
	# `paddle.set_physics_process` mirrors the actual enabled state so we
	# don't disable player input just because set_enabled refused.
	paddle.set_physics_process(not _enabled)
	autoplay_toggled.emit(_enabled)


## Force autoplay off without restoring on timeout_ended; the player re-toggles manually.
## Bypasses toggle() because timeout owns paddle physics during the walk; flipping
## set_physics_process here fights the walk-off freeze.
func _on_timeout_started() -> void:
	if not _enabled:
		return
	set_enabled(false)
	autoplay_toggled.emit(false)


func _ball_approaching() -> bool:
	return ball.linear_velocity.x < 0.0 and ball.position.x > paddle.position.x


func _get_paddle_speed() -> float:
	return paddle.get_speed()
