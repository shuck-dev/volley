class_name TierRewardHandler
extends Node

## Consumes ball.tier_advanced and ball.at_max_speed_changed to fire tier-completion rewards.
## Tier 0 peak: no reward. Tier 1 peak: friendship tick + counter flourish signal.
## Top-tier peak: currency bank once per rally. First-reach: ball level bump.

signal tier1_peak_reached
## Carries the currency amount banked on top-tier completion.
signal top_peak_currency_banked(amount: int)

## FP awarded when the player exits tier 1 into tier 2.
@export_range(0, 20) var tier1_friendship_tick: int = 1
## Currency banked once per rally when the top tier completes and Peak opens.
@export_range(0, 100) var peak_currency_amount: int = 10

var _item_manager: Node
var _ball: Ball

var _peak_just_opened: bool = false
var _peak_banked_this_rally: bool = false
var _tiers_reached_first_time: Array[int] = []
## True when the next paddle hit should award the tier-1 friendship tick.
var _pending_friendship_tick: bool = false


func bind(ball: Ball, item_manager: Node) -> void:
	_item_manager = item_manager
	_set_ball(ball)


func on_paddle_hit() -> void:
	if not _pending_friendship_tick:
		return

	_item_manager.add_friendship_points(tier1_friendship_tick)
	_pending_friendship_tick = false


func reset_rally() -> void:
	_peak_banked_this_rally = false
	_pending_friendship_tick = false


func _set_ball(ball: Ball) -> void:
	if _ball != null:
		_disconnect_ball(_ball)

	_ball = ball

	if _ball != null:
		_ball.at_max_speed_changed.connect(_on_ball_peak_changed)
		_ball.tier_advanced.connect(_on_ball_tier_advanced)
		_ball.missed.connect(reset_rally)


func _disconnect_ball(ball: Ball) -> void:
	if ball.at_max_speed_changed.is_connected(_on_ball_peak_changed):
		ball.at_max_speed_changed.disconnect(_on_ball_peak_changed)

	if ball.tier_advanced.is_connected(_on_ball_tier_advanced):
		ball.tier_advanced.disconnect(_on_ball_tier_advanced)

	if ball.missed.is_connected(reset_rally):
		ball.missed.disconnect(reset_rally)


func _on_ball_peak_changed(in_peak: bool) -> void:
	if in_peak:
		_peak_just_opened = true


func _on_ball_tier_advanced(new_tier: int) -> void:
	var completed_tier: int = new_tier - 1 if not _peak_just_opened else new_tier
	_peak_just_opened = false

	_handle_first_reach(completed_tier)

	if completed_tier == 0:
		return

	var is_top_tier: bool = (
		new_tier >= GameRules.speed_tiers.tier_count() - 1 and _ball != null and _ball.in_peak
	)
	if is_top_tier:
		_handle_top_peak()
	else:
		_handle_tier1_peak()


func _handle_first_reach(completed_tier: int) -> void:
	if _tiers_reached_first_time.has(completed_tier):
		return

	_tiers_reached_first_time.append(completed_tier)

	if _ball == null or _ball.item_key.is_empty():
		return

	_item_manager.upgrade_ball(_ball.item_key)


func _handle_tier1_peak() -> void:
	_pending_friendship_tick = true
	tier1_peak_reached.emit()


func _handle_top_peak() -> void:
	if _peak_banked_this_rally:
		return

	_peak_banked_this_rally = true
	_item_manager.add_friendship_points(peak_currency_amount)
	top_peak_currency_banked.emit(peak_currency_amount)
