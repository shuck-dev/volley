extends GutTest

# Verifies the event-based causality system: event dispatch, modify_stat_until_miss,
# and oscillate_stat outcomes. These are the building blocks for items like Cadence.

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


func _make_effect(
	trigger_type: StringName, outcome_type: StringName, parameters: Dictionary
) -> Effect:
	var trigger := Trigger.new()
	trigger.type = trigger_type

	var outcome := Outcome.new()
	outcome.type = outcome_type
	outcome.parameters = parameters

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1
	return effect


# --- event dispatch ---
func test_process_event_fires_matching_trigger() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_max_speed_reached")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"] + 30.0,
	)


func test_process_event_ignores_non_matching_trigger() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_hit")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"],
	)


func test_event_effect_not_applied_on_register() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"],
	)


func test_process_event_scales_value_by_level() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 2)

	_manager.process_event(&"on_max_speed_reached")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"] + 60.0,
	)


# --- modify_stat_until_miss ---
func test_modify_stat_until_miss_stacks_on_repeated_events() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_max_speed_reached")
	_manager.process_event(&"on_max_speed_reached")
	_manager.process_event(&"on_max_speed_reached")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"] + 90.0,
	)


func test_miss_event_clears_until_miss_modifiers() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_max_speed_reached")
	_manager.process_event(&"on_max_speed_reached")

	_manager.process_event(&"on_miss")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"],
	)


func test_miss_preserves_permanent_modifiers() -> void:
	var always_effect := _make_effect(
		&"always",
		&"modify_stat",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 50.0,
		}
	)
	var event_effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [always_effect, event_effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_max_speed_reached")

	_manager.process_event(&"on_miss")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"] + 50.0,
	)


func test_unregister_removes_event_effects() -> void:
	var effect := _make_effect(
		&"on_max_speed_reached",
		&"modify_stat_until_miss",
		{
			&"stat_key": &"ball_speed_max_range",
			&"operation": &"add",
			&"value": 30.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_max_speed_reached")

	_manager.unregister_source(item)

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.BASE_STATS[&"ball_speed_max_range"],
	)


# --- oscillate_stat ---
func test_oscillate_stat_changes_value_over_time() -> void:
	var effect := _make_effect(
		&"always",
		&"oscillate_stat",
		{
			&"stat_key": &"ball_speed_min",
			&"wave_range": 20.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var base_value: float = GameRules.BASE_STATS[&"ball_speed_min"]
	var found_different := false
	for frame_index in range(60):
		_manager.process_frame(0.016)
		if not is_equal_approx(_manager.get_stat(&"ball_speed_min"), base_value):
			found_different = true
			break

	assert_true(found_different, "Oscillation should change stat value within 60 frames")


func test_oscillate_stat_stays_within_wave_range() -> void:
	var wave_range := 20.0
	var effect := _make_effect(
		&"always",
		&"oscillate_stat",
		{
			&"stat_key": &"ball_speed_min",
			&"wave_range": wave_range,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var base_value: float = GameRules.BASE_STATS[&"ball_speed_min"]
	var min_observed := base_value
	var max_observed := base_value

	for frame_index in range(300):
		_manager.process_frame(0.016)
		var current_value: float = _manager.get_stat(&"ball_speed_min")
		min_observed = minf(min_observed, current_value)
		max_observed = maxf(max_observed, current_value)

	assert_true(
		min_observed >= base_value - wave_range,
		"Min observed %f should be >= %f" % [min_observed, base_value - wave_range],
	)
	assert_true(
		max_observed <= base_value + wave_range,
		"Max observed %f should be <= %f" % [max_observed, base_value + wave_range],
	)


func test_oscillate_stat_scales_range_by_level() -> void:
	var wave_range := 20.0
	var effect := _make_effect(
		&"always",
		&"oscillate_stat",
		{
			&"stat_key": &"ball_speed_min",
			&"wave_range": wave_range,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 2)

	var base_value: float = GameRules.BASE_STATS[&"ball_speed_min"]
	var scaled_range: float = wave_range * 2.0

	for frame_index in range(300):
		_manager.process_frame(0.016)
		var current_value: float = _manager.get_stat(&"ball_speed_min")
		assert_true(
			(
				current_value >= base_value - scaled_range
				and current_value <= base_value + scaled_range
			),
			(
				"Value %f should be within level-2 range [%f, %f]"
				% [current_value, base_value - scaled_range, base_value + scaled_range]
			),
		)


func test_unregister_stops_oscillation() -> void:
	var effect := _make_effect(
		&"always",
		&"oscillate_stat",
		{
			&"stat_key": &"ball_speed_min",
			&"wave_range": 20.0,
		}
	)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	for frame_index in range(60):
		_manager.process_frame(0.016)

	_manager.unregister_source(item)

	assert_eq(_manager.get_stat(&"ball_speed_min"), GameRules.BASE_STATS[&"ball_speed_min"])
