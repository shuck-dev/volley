class_name RallyGate


## True when a rally is in progress: timeout idle AND a ball in PLAY.
static func is_rally_in_progress(timeout_active: bool, ball_in_play: bool) -> bool:
	return not timeout_active and ball_in_play
