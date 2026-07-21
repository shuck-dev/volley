class_name TierRewardHandler
extends Node

## Fires on_consolidation through the effect system on every tier-up; handles first-reach upgrades.

## Fired after on_consolidation is processed so Court can read the updated soul_multiplier.
signal consolidation_fired

var _item_manager: Node

# Per-ball flag guarding the once-per-rally final-consolidation reward.
var _final_banked_by_ball: Dictionary = {}
var _tiers_reached_first_time_by_ball: Dictionary = {}


func _ready() -> void:
	add_to_group(&"tier_reward_handlers")


func bind(item_manager: Node) -> void:
	_item_manager = item_manager


func reset_rally(ball: Ball = null) -> void:
	if ball == null:
		_final_banked_by_ball.clear()
		_tiers_reached_first_time_by_ball.clear()
	else:
		_final_banked_by_ball.erase(ball)
		_tiers_reached_first_time_by_ball.erase(ball)


## Prunes a removed ball's entries so the dicts don't grow unbounded.
func on_ball_removed(ball: Ball) -> void:
	_final_banked_by_ball.erase(ball)
	_tiers_reached_first_time_by_ball.erase(ball)


## Pays the consolidation reward for whichever ball crossed a tier; driven by BallReconciler.ball_tier_advanced.
func on_tier_advanced(ball: Ball, new_tier: int) -> void:
	var is_entering_final: bool = ball != null and ball.in_final
	var completed_tier: int = new_tier - 1 if not is_entering_final else new_tier

	_handle_first_reach(ball, completed_tier)

	var is_top_tier: bool = (
		GameRules.speed_tiers.is_top_tier(GameRules.speed_tiers.get_tier(new_tier))
		and ball != null
		and ball.in_final
	)

	if is_top_tier and _final_banked_by_ball.get(ball, false):
		return

	if is_top_tier:
		_final_banked_by_ball[ball] = true

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
