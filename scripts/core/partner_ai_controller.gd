class_name PartnerAIController
extends PaddleAIController


## Recruitment can happen mid-rally, after the live ball already registered; ball_added won't
## fire again for it, so check directly rather than wait on a signal that has already passed.
func _ready() -> void:
	super._ready()
	if BallTracker.has_ball_in_play():
		_enabled = true


## Auto-enables on the first tracker-visible ball; base class handles auto-disable on empty.
func _on_tracker_ball_added(new_ball: Ball) -> void:
	super(new_ball)
	if not _enabled:
		_enabled = true


func _court_side_sign() -> float:
	return 1.0


func _get_paddle_speed() -> float:
	return GameRules.paddle.paddle_speed
