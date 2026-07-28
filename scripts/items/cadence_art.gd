class_name CadenceArt
extends ItemArt

## Fires shift_cue when this ball's StatShift changes mode.

@export var shift_cue: CPUParticles2D

var _ball: Ball
var _connected_shifts: Array[StatShift] = []


func watch_ball(ball: Ball) -> void:
	_ball = ball
	if not ball.play_state_changed.is_connected(_on_play_state_changed):
		ball.play_state_changed.connect(_on_play_state_changed)
	if not BallManager.item_level_changed.is_connected(_on_item_level_changed):
		BallManager.item_level_changed.connect(_on_item_level_changed)
	_connect_shifts()


func _on_play_state_changed(_state: Ball.PlayState) -> void:
	_connect_shifts()


func _on_item_level_changed(ball_key: String) -> void:
	if _ball != null and ball_key == _ball.ball_key:
		_connect_shifts()


func _connect_shifts() -> void:
	if _ball == null:
		return

	var current_shifts: Array[StatShift] = BallManager.get_effect_manager().get_shifts(
		_ball.ball_key
	)

	# register_source rebuilds StatShift instances wholesale on level-up; prune stale
	# connections so a re-registered ball's cue doesn't keep listening to a discarded shift.
	for shift in _connected_shifts:
		if shift not in current_shifts and shift.shifted.is_connected(_on_shifted):
			shift.shifted.disconnect(_on_shifted)

	for shift in current_shifts:
		if not shift.shifted.is_connected(_on_shifted):
			shift.shifted.connect(_on_shifted)

	_connected_shifts = current_shifts


func _on_shifted(_mode: StatShift.Mode) -> void:
	if shift_cue == null:
		return
	shift_cue.restart()
	shift_cue.emitting = true
