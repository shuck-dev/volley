class_name TierRewardHandler
extends Node

## Handles the consolidation reward on every tier-up.


## Pays the consolidation reward for whichever ball crossed a tier.
func on_tier_advanced(ball: Ball, _new_tier: int) -> void:
	if ball == null:
		return

	ball.increment_soul_multiplier(1.0)

	var payout := roundi(ball.accumulated_soul * ball.get_stats().consolidation_multiplier)

	BallManager.add_soul(payout)
	ball.reset_accumulated_soul()
