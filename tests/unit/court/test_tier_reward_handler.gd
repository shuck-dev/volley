extends GutTest

# TierRewardHandler: on_consolidation event, first-reach upgrades, and reward signal.

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

	var venue_source: Resource = load("res://scripts/core/venue_effect_source.gd").new()
	_manager.register_source(venue_source, 1)

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


# --- soul_multiplier starts at base 1 ---


func test_soul_multiplier_starts_at_one() -> void:
	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), 1.0, 0.001)


# --- on_consolidation fires through effect manager ---


func test_tier1_consolidation_increments_soul_multiplier() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()

	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), 2.0, 0.001)


func test_tier2_consolidation_increments_soul_multiplier_again() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()

	_ball.current_tier = 2
	_ball.advance_tier()

	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), 3.0, 0.001)


func test_tier0_consolidation_increments_soul_multiplier() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()

	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), 2.0, 0.001)


func test_consolidation_fired_signal_emitted_on_tier_advance() -> void:
	watch_signals(_handler)

	_ball.current_tier = 1
	_ball.advance_tier()

	assert_signal_emitted(_handler, "consolidation_fired")


func test_consolidation_fired_emitted_on_tier0() -> void:
	watch_signals(_handler)

	_ball.current_tier = 0
	_ball.advance_tier()

	assert_signal_emitted(_handler, "consolidation_fired")


# --- reset on miss ---


func test_soul_multiplier_resets_to_one_after_miss() -> void:
	_ball.current_tier = 1
	_ball.advance_tier()

	_manager.process_event(&"on_miss")

	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), 1.0, 0.001)


# --- once-per-rally guard at top Peak ---


func test_top_tier_consolidation_fires_only_once_per_rally() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var after_first: float = _manager.get_stat(&"soul_multiplier")

	_ball.in_peak = true
	_ball.tier_advanced.emit(_top_tier())

	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), after_first, 0.001)


func test_new_rally_allows_top_tier_to_consolidate_again() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var after_first: float = _manager.get_stat(&"soul_multiplier")

	_handler.reset_rally()

	_ball.in_peak = false
	_ball.current_tier = _top_tier()
	_ball.advance_tier()

	assert_almost_eq(_manager.get_stat(&"soul_multiplier"), after_first + 1.0, 0.001)


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

	assert_signal_emitted(_handler, "ball_upgrade_earned")


func test_ball_upgrade_earned_not_emitted_on_second_reach() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()

	watch_signals(_handler)
	_handler.reset_rally()
	_ball.reset_speed()
	_ball.current_tier = 0
	_ball.advance_tier()

	assert_signal_not_emitted(_handler, "ball_upgrade_earned")
