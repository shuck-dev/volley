extends GutTest

# TierRewardHandler: unified soul curve, first-reach upgrades, and reward signal.

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


# --- tier 0 completion: no soul reward ---


func test_tier0_completion_gives_no_friendship_points() -> void:
	var before: int = _manager.get_friendship_point_balance()

	_ball.current_tier = 0
	_ball.advance_tier()

	assert_eq(_manager.get_friendship_point_balance(), before)


func test_tier0_completion_no_signal_emitted() -> void:
	watch_signals(_handler)

	_ball.current_tier = 0
	_ball.advance_tier()

	assert_signal_not_emitted(_handler, "soul_reward_earned")


# --- unified curve: tier N banks base * N ---


func test_tier1_completion_banks_base_times_1() -> void:
	var before: int = _manager.get_friendship_point_balance()

	_ball.current_tier = 1
	_ball.advance_tier()

	assert_eq(_manager.get_friendship_point_balance(), before + _handler.soul_per_tier_base * 1)


func test_tier2_completion_banks_base_times_2() -> void:
	var before: int = _manager.get_friendship_point_balance()

	_ball.current_tier = 2
	_ball.advance_tier()

	assert_eq(_manager.get_friendship_point_balance(), before + _handler.soul_per_tier_base * 2)


func test_soul_reward_earned_emitted_with_correct_amount_tier1() -> void:
	watch_signals(_handler)

	_ball.current_tier = 1
	_ball.advance_tier()

	assert_signal_emitted_with_parameters(
		_handler, "soul_reward_earned", [_handler.soul_per_tier_base * 1, _handler.soul_anchor]
	)


func test_soul_reward_earned_emitted_with_correct_amount_top_tier() -> void:
	watch_signals(_handler)

	_ball.current_tier = _top_tier()
	_ball.advance_tier()

	var expected_amount: int = _handler.soul_per_tier_base * _top_tier()
	assert_signal_emitted_with_parameters(
		_handler, "soul_reward_earned", [expected_amount, _handler.soul_anchor]
	)


# --- once-per-rally guard at top Peak ---


func test_top_tier_soul_banks_only_once_per_rally() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var after_first: int = _manager.get_friendship_point_balance()

	_ball.in_peak = true
	_ball.tier_advanced.emit(_top_tier())

	assert_eq(_manager.get_friendship_point_balance(), after_first)


func test_new_rally_allows_top_tier_to_bank_again() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var after_first_peak: int = _manager.get_friendship_point_balance()

	_handler.reset_rally()

	_ball.in_peak = false
	_ball.current_tier = _top_tier()
	_ball.advance_tier()

	assert_eq(
		_manager.get_friendship_point_balance(),
		after_first_peak + _handler.soul_per_tier_base * _top_tier()
	)


func test_banked_reward_survives_peak_miss_reset() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var balance_after_peak: int = _manager.get_friendship_point_balance()

	_ball.reset_speed()

	assert_eq(_manager.get_friendship_point_balance(), balance_after_peak)


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


func test_ball_upgrade_earned_emitted_on_first_reach() -> void:
	watch_signals(_handler)

	_ball.current_tier = 0
	_ball.advance_tier()

	assert_signal_emitted_with_parameters(_handler, "ball_upgrade_earned", [_handler.soul_anchor])


func test_ball_upgrade_earned_not_emitted_on_second_reach() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()

	watch_signals(_handler)
	_handler.reset_rally()
	_ball.reset_speed()
	_ball.current_tier = 0
	_ball.advance_tier()

	assert_signal_not_emitted(_handler, "ball_upgrade_earned")
