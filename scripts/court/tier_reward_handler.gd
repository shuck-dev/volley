class_name TierRewardHandler
extends Node

## Fires on_consolidation through the effect system on every tier-up; handles first-reach upgrades.

## Fired after on_consolidation is processed so Court can read the updated soul_multiplier.
signal consolidation_fired

var _item_manager: ItemManager

var _tiers_reached_first_time_by_ball: Dictionary = {}


func _ready() -> void:
	add_to_group(&"tier_reward_handlers")


func bind(item_manager: Node) -> void:
	_item_manager = item_manager


func reset_rally(ball: Ball = null) -> void:
	if ball == null:
		_tiers_reached_first_time_by_ball.clear()
	else:
		_tiers_reached_first_time_by_ball.erase(ball)


## Prunes a removed ball's entries so the dict doesn't grow unbounded.
func on_ball_removed(ball: Ball) -> void:
	_tiers_reached_first_time_by_ball.erase(ball)


## Pays the consolidation reward for whichever ball crossed a tier; driven by BallReconciler.ball_tier_advanced.
func on_tier_advanced(ball: Ball, new_tier: int) -> void:
	var completed_tier: int = new_tier - 1

	_handle_first_reach(ball, completed_tier)

	if ball != null:
		ball.increment_soul_multiplier(1.0)

	_item_manager.process_event(&"on_consolidation")
	consolidation_fired.emit()


func _handle_first_reach(ball: Ball, completed_tier: int) -> void:
	if not _tiers_reached_first_time_by_ball.has(ball):
		_tiers_reached_first_time_by_ball[ball] = []

	var reached: Array = _tiers_reached_first_time_by_ball[ball]

	if reached.has(completed_tier):
		return

	reached.append(completed_tier)

	if ball == null or ball.item_key.is_empty():
		return

	# Deferred: this runs inside the ball's physics callback, where the rack rebuild upgrade triggers is illegal.
	_item_manager.upgrade_ball.call_deferred(ball.item_key)
