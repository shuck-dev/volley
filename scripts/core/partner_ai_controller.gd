class_name PartnerAIController
extends PaddleAIController


## Auto-enables on the first tracker-visible ball; base class handles auto-disable on empty.
func _on_tracker_ball_added(new_ball: Ball) -> void:
	super(new_ball)
	if not _enabled:
		set_enabled(true)


func _ball_approaching() -> bool:
	return ball.linear_velocity.x > 0.0 and ball.position.x < paddle.position.x


func _get_paddle_speed() -> float:
	return GameRules.paddle.paddle_speed
