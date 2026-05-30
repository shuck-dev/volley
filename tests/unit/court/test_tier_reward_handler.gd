extends GutTest

# TierRewardHandler: tier-completion reward dispatch, first-reach ball upgrades.

var _handler: Node
var _ball: Node
var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	add_child_autofree(_manager)

	_manager.state.item_levels["base_ball"] = 1

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	_ball.item_key = "base_ball"
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(_ball.tier_floor, 0.0)

	_handler = load("res://scripts/court/tier_reward_handler.gd").new()
	add_child_autofree(_handler)
	_handler.bind(_ball, _manager)


func _top_tier() -> int:
	return GameRules.speed_tiers.tier_count() - 1


# --- tier 0 completion: no reward ---


func test_tier0_completion_gives_no_friendship_points() -> void:
	var before: int = _manager.get_friendship_point_balance()
	_ball.current_tier = 0
	_ball.advance_tier()
	assert_eq(_manager.get_friendship_point_balance(), before)


func test_tier0_completion_no_pending_friendship_tick() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()
	assert_false(_handler._pending_friendship_tick)


# --- tier 1 completion: friendship tick on next hit + signal ---


func test_tier1_completion_sets_pending_friendship_tick() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()
	assert_true(_handler._pending_friendship_tick)


func test_tier1_completion_emits_tier1_peak_reached() -> void:
	watch_signals(_handler)
	_ball.current_tier = 1
	_ball.advance_tier()
	assert_signal_emitted(_handler, "tier1_peak_reached")


func test_tier1_friendship_tick_awarded_on_next_paddle_hit() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()
	var before: int = _manager.get_friendship_point_balance()
	_handler.on_paddle_hit()
	assert_eq(_manager.get_friendship_point_balance(), before + _handler.tier1_friendship_tick)


func test_tier1_friendship_tick_awarded_once_not_twice() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()
	var before: int = _manager.get_friendship_point_balance()
	_handler.on_paddle_hit()
	_handler.on_paddle_hit()
	assert_eq(_manager.get_friendship_point_balance(), before + _handler.tier1_friendship_tick)


# --- top-tier completion: currency bank ---


func test_top_tier_completion_banks_currency() -> void:
	_ball.current_tier = _top_tier()
	var before: int = _manager.get_friendship_point_balance()
	_ball.advance_tier()
	assert_eq(_manager.get_friendship_point_balance(), before + _handler.peak_currency_amount)


func test_top_tier_completion_emits_top_peak_currency_banked() -> void:
	watch_signals(_handler)
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	assert_signal_emitted_with_parameters(
		_handler, "top_peak_currency_banked", [_handler.peak_currency_amount]
	)


func test_top_tier_currency_banks_only_once_per_rally() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var after_first: int = _manager.get_friendship_point_balance()

	_ball.in_peak = true
	_ball.tier_advanced.emit(_top_tier())
	assert_eq(_manager.get_friendship_point_balance(), after_first)


func test_banked_reward_survives_peak_miss_reset() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var balance_after_peak: int = _manager.get_friendship_point_balance()

	_ball.reset_speed()
	assert_eq(_manager.get_friendship_point_balance(), balance_after_peak)


func test_new_rally_allows_currency_bank_again() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var after_first_peak: int = _manager.get_friendship_point_balance()

	_handler.reset_rally()

	_ball.in_peak = false
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	assert_eq(
		_manager.get_friendship_point_balance(), after_first_peak + _handler.peak_currency_amount
	)


# --- first-reach ball upgrade ---


func test_first_tier0_reach_upgrades_ball() -> void:
	assert_eq(_manager.get_level("base_ball"), 1)
	_ball.current_tier = 0
	_ball.advance_tier()
	assert_eq(_manager.get_level("base_ball"), 2)


func test_second_tier0_reach_does_not_upgrade_again() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()
	var after_first: int = _manager.get_level("base_ball")

	_handler.reset_rally()
	_ball.reset_speed()
	_ball.current_tier = 0
	_ball.advance_tier()
	assert_eq(_manager.get_level("base_ball"), after_first)


func test_first_top_tier_reach_upgrades_ball() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()
	assert_eq(_manager.get_level("base_ball"), 2)

	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	assert_eq(_manager.get_level("base_ball"), 3)


func test_upgrade_stops_at_max_level() -> void:
	_manager.state.item_levels["base_ball"] = 10

	_ball.current_tier = 0
	_ball.advance_tier()
	assert_eq(_manager.get_level("base_ball"), 10)


# --- reset_rally clears pending tick ---


func test_reset_rally_clears_pending_friendship_tick() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()
	assert_true(_handler._pending_friendship_tick)
	_handler.reset_rally()
	assert_false(_handler._pending_friendship_tick)
