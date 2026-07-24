extends GutTest

# Verifies the event-based causality system: event dispatch and modify_stat_until_miss.

@warning_ignore("shadowed_global_identifier")
const HalveStreakOutcome = preload("res://scripts/items/effect/outcomes/halve_streak_outcome.gd")

var _manager: EffectManager


func before_each() -> void:
	_manager = EffectManager.new()
	add_child_autofree(_manager)


func _make_item(item_key: String, effects: Array[Effect]) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = item_key
	item.max_level = 3
	item.effects = effects
	return item


func _make_until_miss_effect(stat_key: StringName, operation: StringName, value: float) -> Effect:
	var outcome := StatUntilMissOutcome.new()
	outcome.stat_key = stat_key
	outcome.operation = operation
	outcome.value = value

	var trigger := Trigger.new()
	trigger.type = &"on_hit"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1
	return effect


func test_process_event_fires_matching_trigger() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_hit")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 30.0,
	)


func test_process_event_ignores_non_matching_trigger() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_tier_completed")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range,
	)


func test_event_effect_not_applied_on_register() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range,
	)


func test_process_event_scales_value_by_level() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 2)

	_manager.process_event(&"on_hit")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 60.0,
	)


func test_modify_stat_until_miss_stacks_on_repeated_events() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_hit")
	_manager.process_event(&"on_hit")
	_manager.process_event(&"on_hit")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 90.0,
	)


func test_miss_event_clears_until_miss_modifiers() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_hit")
	_manager.process_event(&"on_hit")

	_manager.process_event(&"on_miss")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range,
	)


func test_miss_preserves_permanent_modifiers() -> void:
	var always_outcome := StatOutcome.new()
	always_outcome.stat_key = &"ball_speed_max_range"
	always_outcome.operation = &"add"
	always_outcome.value = 50.0

	var always_trigger := Trigger.new()
	always_trigger.type = &"always"

	var always_effect := Effect.new()
	always_effect.trigger = always_trigger
	always_effect.outcomes = [always_outcome]
	always_effect.min_active_level = 1

	var event_effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [always_effect, event_effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_hit")

	_manager.process_event(&"on_miss")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 50.0,
	)


func test_unregister_removes_event_effects() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_hit")

	_manager.unregister_source(item)

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range,
	)


func test_process_event_returns_empty_array_when_no_game_actions() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var actions: Array[StringName] = _manager.process_event(&"on_hit")

	assert_eq(actions.size(), 0)


func test_process_event_returns_game_action_from_outcome() -> void:
	var outcome := GameActionOutcome.new()
	outcome.action_key = &"test_action"

	var trigger := Trigger.new()
	trigger.type = &"on_miss"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var actions: Array[StringName] = _manager.process_event(&"on_miss")

	assert_true(actions.has(&"test_action"))


func test_halve_streak_returns_action_on_miss() -> void:
	var outcome := HalveStreakOutcome.new()

	var trigger := Trigger.new()
	trigger.type = &"on_miss"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := _make_item("halve_source", [effect])
	_manager.register_source(item, 1)

	var actions: Array[StringName] = _manager.process_event(&"on_miss")

	assert_true(actions.has(&"halve_streak"))


func test_halve_streak_not_returned_for_other_events() -> void:
	var outcome := HalveStreakOutcome.new()

	var trigger := Trigger.new()
	trigger.type = &"on_miss"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := _make_item("halve_source", [effect])
	_manager.register_source(item, 1)

	var actions: Array[StringName] = _manager.process_event(&"on_hit")

	assert_false(actions.has(&"halve_streak"))
