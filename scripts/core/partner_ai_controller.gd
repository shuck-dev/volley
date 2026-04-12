class_name PartnerAIController
extends PaddleAIController


## Skips base _ready(): buffer init deferred until ball is injected via enable_with_ball().
func _ready() -> void:
	pass


func enable_with_ball(target_ball: RigidBody2D) -> void:
	assert(not _enabled, "enable_with_ball called on already-enabled controller")
	ball = target_ball
	_position_buffer.resize(config.reaction_delay_frames)
	_position_buffer.fill(0.0)
	set_enabled(true)


func _ball_approaching() -> bool:
	return ball.linear_velocity.x > 0.0 and ball.position.x < paddle.position.x


func _is_ball_behind() -> bool:
	return ball.position.x > paddle.position.x


func _get_paddle_speed() -> float:
	return GameRules.base_stats[&"paddle_speed"]
