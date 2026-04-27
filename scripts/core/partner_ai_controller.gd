class_name PartnerAIController
extends PaddleAIController


## Auto-enables on the first ball it sees from the bound tracker; auto-disables
## when the tracker empties (handled by the base class). Court calls
## `bind_tracker()` after activating the partner.
func _on_tracker_ball_added(new_ball: Ball) -> void:
	super(new_ball)
	if not _enabled:
		set_enabled(true)


func _ball_approaching() -> bool:
	return ball.linear_velocity.x > 0.0 and ball.position.x < paddle.position.x


func _is_ball_behind() -> bool:
	return ball.position.x > paddle.position.x


func _get_paddle_speed() -> float:
	return GameRules.base_stats[&"paddle_speed"]
