class_name PartnerAIController
extends PaddleAIController


func _ready() -> void:
	super._ready()
	if BallTracker.has_ball_in_play():
		_enabled = true


## Auto-enables on the first tracker-visible ball.
func _on_tracker_ball_added(new_ball: Ball) -> void:
	super(new_ball)
	if not _enabled:
		_enabled = true


func _court_side_sign() -> float:
	return 1.0


func _get_paddle_speed() -> float:
	return GameRules.paddle.paddle_speed
