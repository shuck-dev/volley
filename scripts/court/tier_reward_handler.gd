class_name TierRewardHandler
extends Node

## Handles the consolidation reward on every tier-up.

## Fired after the tier-up is processed so Court can read the updated soul_multiplier.
signal consolidation_fired


func _ready() -> void:
	add_to_group(&"tier_reward_handlers")


## Pays the consolidation reward for whichever ball crossed a tier; driven by BallReconciler.ball_tier_advanced.
func on_tier_advanced(ball: Ball, _new_tier: int) -> void:
	if ball != null:
		ball.increment_soul_multiplier(1.0)

	consolidation_fired.emit()
