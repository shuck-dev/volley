class_name PartnerPaddle
extends Paddle

@export var controller: PartnerAIController


func _get_stat(key: StringName) -> float:
	return GameRules.base_stats[key]


func _bind_stat_updates() -> void:
	pass


## BallTracker calls this to retarget the partner across balls. The controller
## owns its own enable/disable state via the tracker subscription, so this is
## just a ball-pointer update for any non-controller consumers; tests assert
## the partner is informed of the active ball.
func set_ball(_value: RigidBody2D) -> void:
	pass
