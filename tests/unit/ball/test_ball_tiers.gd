extends GutTest

# Tier state machine and final-consolidation window on Ball: advance, completion event, climb, reset.

var _ball: Ball
var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(_ball.tier_floor, 0.0)


func _top_tier() -> int:
	return GameRules.speed_tiers.tiers.size() - 1


# --- tier bounds derive from the table ---
func test_tier_floor_and_ceiling_track_current_tier() -> void:
	_ball.current_tier = 1
	var world_max: float = _ball.ball_world_max_speed
	var tier: SpeedTier = GameRules.speed_tiers.get_tier(1)
	assert_almost_eq(_ball.tier_floor, tier.floor_fraction * world_max, 0.01)
	assert_almost_eq(_ball.tier_ceiling, tier.ceiling_fraction * world_max, 0.01)


# --- advance steps up and drops to the new floor ---
func test_advance_tier_steps_up_and_drops_to_floor() -> void:
	_ball.current_tier = 0
	_ball.advance_tier()
	assert_eq(_ball.current_tier, 1)
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01)


func test_advance_tier_emits_tier_advanced() -> void:
	_ball.current_tier = 0
	watch_signals(_ball)
	_ball.advance_tier()
	assert_signal_emitted_with_parameters(_ball, "tier_advanced", [1])


func test_advance_tier_fires_completion_event() -> void:
	var item := _probe_item(&"on_tier_completed")
	_manager._effect_manager.register_source(item, 1)
	_ball.current_tier = 0
	var before: float = Stats.resolve(
		GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager
	)

	_ball.advance_tier()

	var after: float = Stats.resolve(
		GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager
	)
	assert_almost_eq(after, before + 30.0, 0.01, "on_tier_completed fired through the item bus")


# --- top tier opens the final-consolidation window instead of stepping up ---
func test_top_tier_completion_opens_final_consolidation() -> void:
	_ball.current_tier = _top_tier()
	watch_signals(_ball)
	_ball.advance_tier()
	assert_true(_ball.in_final, "completing the top tier opens the final-consolidation window")
	assert_eq(_ball.current_tier, _top_tier(), "tier does not step past the top")
	assert_signal_emitted_with_parameters(_ball, "at_max_speed_changed", [true])


func test_final_consolidation_climbs_hit_by_hit_without_exceeding_world_max() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	var before: float = _ball.speed
	_ball.increase_speed()
	assert_gt(_ball.speed, before, "final consolidation keeps climbing on each hit")

	for _i in range(200):
		_ball.increase_speed()

	assert_true(_ball.speed <= _ball.ball_world_max_speed + 0.01, "never exceeds the world max")


# --- miss resets tier and closes the final-consolidation window ---
func test_reset_speed_closes_final_consolidation_and_returns_to_tier_zero() -> void:
	_ball.current_tier = _top_tier()
	_ball.advance_tier()
	watch_signals(_ball)

	_ball.reset_speed()

	assert_false(_ball.in_final)
	assert_eq(_ball.current_tier, 0)
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01)
	assert_signal_emitted_with_parameters(_ball, "at_max_speed_changed", [false])


func test_speed_changed_carries_tier_band() -> void:
	_ball.current_tier = 1
	watch_signals(_ball)
	_ball.set_speed_for_streak(2)
	assert_signal_emitted_with_parameters(
		_ball, "speed_changed", [_ball.speed, _ball.tier_floor, _ball.tier_ceiling]
	)


# Item armed on an event so process_event leaves an assertable stat bump.
func _probe_item(event_type: StringName) -> ItemDefinition:
	var outcome := StatUntilMissOutcome.new()
	outcome.stat_key = &"ball_speed_max_range"
	outcome.operation = &"add"
	outcome.value = 30.0

	var trigger := Trigger.new()
	trigger.type = event_type

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := ItemDefinition.new()
	item.key = "tier_probe"
	item.max_level = 3
	item.effects = [effect]
	return item
