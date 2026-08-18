class_name TierRewardHandler
extends Node

## Handles the consolidation reward on every tier-up.

@export var soul_burst_handler: SoulBurstHandler


## Computes the consolidation reward for whichever ball crossed a tier and hands it to
## soul_burst_handler for delivery; the burst handler is what actually pays it out.
func on_tier_advanced(ball: Ball, _new_tier: int) -> void:
	if ball == null:
		return

	ball.increment_soul_multiplier(1.0)

	var payout := roundi(ball.accumulated_soul * ball.get_stats().consolidation_multiplier)
	ball.reset_accumulated_soul()

	soul_burst_handler.release_burst(ball, payout)
