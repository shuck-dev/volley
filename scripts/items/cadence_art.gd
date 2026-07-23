class_name CadenceArt
extends ItemArt

## Fires shift_cue when this ball's StatShift changes mode.

@export var shift_cue: CPUParticles2D

var _ball: Ball


func watch_ball(ball: Ball) -> void:
	_ball = ball
	if not ball.play_state_changed.is_connected(_on_play_state_changed):
		ball.play_state_changed.connect(_on_play_state_changed)
	_connect_shifts()


func _on_play_state_changed(_state: Ball.PlayState) -> void:
	_connect_shifts()


func _connect_shifts() -> void:
	if _ball == null:
		return
	for shift: StatShift in ItemManager.get_shifts(_ball.item_key):
		if not shift.shifted.is_connected(_on_shifted):
			shift.shifted.connect(_on_shifted)


func _on_shifted(_mode: StatShift.Mode) -> void:
	if shift_cue == null:
		return
	shift_cue.restart()
	shift_cue.emitting = true
