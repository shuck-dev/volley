class_name PartnerAIController
extends PaddleAIController


## Auto-enables on the first tracker-visible ball; base class handles auto-disable on empty.
func _on_tracker_ball_added(new_ball: Ball) -> void:
	super(new_ball)
	if not _enabled:
		set_enabled(true)


func _court_side_sign() -> float:
	return 1.0


func _get_paddle_speed() -> float:
	return GameRules.paddle.paddle_speed
