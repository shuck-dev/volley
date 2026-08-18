class_name TierRewardHandler
extends Node

## Handles the consolidation reward on every tier-up.

@export var soul_burst_handler: SoulBurstHandler

## Delay between the shake cue and the motes actually spawning.
@export var burst_delay := 1.0


## Computes the consolidation reward for whichever ball crossed a tier and hands it to
## soul_burst_handler for delivery; the burst handler is what actually pays it out.
func on_tier_advanced(ball: Ball, _new_tier: int) -> void:
	if ball == null:
		return

	ball.increment_soul_multiplier(1.0)

	var payout := roundi(ball.accumulated_soul * ball.get_stats().consolidation_multiplier)
	ball.reset_accumulated_soul()

	await get_tree().create_timer(burst_delay).timeout
	if not is_instance_valid(ball) or not is_instance_valid(soul_burst_handler):
		return

	soul_burst_handler.release_burst(ball, payout)
