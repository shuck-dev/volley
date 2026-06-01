class_name TierRewardHandler
extends Node

## Fires on_consolidation through the effect system on every tier-up; handles first-reach upgrades.

## Carries the screen anchor where the upgrade float should appear.
signal ball_upgrade_earned(anchor: Vector2)
## Fired after on_consolidation is processed so Court can read the updated soul_multiplier.
signal consolidation_fired

## Fallback screen position when no ball is bound; normally the float anchors on the ball.
@export var soul_anchor: Vector2 = Vector2(512.0, 300.0)

var _item_manager: Node
var _ball: Ball

var _peak_banked_this_rally: bool = false
var _tiers_reached_first_time: Array[int] = []


func _ready() -> void:
	add_to_group(&"tier_reward_handlers")


func bind(ball: Ball, item_manager: Node) -> void:
	_item_manager = item_manager
	_set_ball(ball)


func reset_rally() -> void:
	_peak_banked_this_rally = false


func _set_ball(ball: Ball) -> void:
	if _ball != null:
		_disconnect_ball(_ball)

	_ball = ball

	if _ball != null:
		_ball.tier_advanced.connect(_on_ball_tier_advanced)
		_ball.missed.connect(reset_rally)


func _disconnect_ball(ball: Ball) -> void:
	if ball.tier_advanced.is_connected(_on_ball_tier_advanced):
		ball.tier_advanced.disconnect(_on_ball_tier_advanced)

	if ball.missed.is_connected(reset_rally):
		ball.missed.disconnect(reset_rally)


func _on_ball_tier_advanced(new_tier: int) -> void:
	var is_entering_peak: bool = _ball != null and _ball.in_peak
	var completed_tier: int = new_tier - 1 if not is_entering_peak else new_tier

	_handle_first_reach(completed_tier)

	var is_top_tier: bool = (
		new_tier >= GameRules.speed_tiers.tier_count() - 1 and _ball != null and _ball.in_peak
	)

	if is_top_tier and _peak_banked_this_rally:
		return

	if is_top_tier:
		_peak_banked_this_rally = true

	_item_manager.process_event(&"on_consolidation")
	consolidation_fired.emit()


func _handle_first_reach(completed_tier: int) -> void:
	if _tiers_reached_first_time.has(completed_tier):
		return

	_tiers_reached_first_time.append(completed_tier)

	if _ball == null or _ball.item_key.is_empty():
		return

	_item_manager.upgrade_ball(_ball.item_key)
	ball_upgrade_earned.emit(_reward_anchor())


## Ball's current screen position, so floats appear where the consolidation happened.
func _reward_anchor() -> Vector2:
	if not is_instance_valid(_ball) or not _ball.is_inside_tree():
		return soul_anchor

	return _ball.get_viewport().get_canvas_transform() * _ball.global_position
