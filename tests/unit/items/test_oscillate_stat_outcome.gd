extends GutTest

# Verifies OscillateStatOutcome: continuous per-frame oscillation and unregister
# stopping the effect.

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


func _make_oscillation_effect(amplitude: float) -> Effect:
	var outcome := OscillateStatOutcome.new()
	outcome.stat_key = &"ball_speed_offset"
	outcome.amplitude = amplitude
	outcome.range_stat_key = &"ball_speed_max_range"

	var trigger := Trigger.new()
	trigger.type = &"always"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1
	return effect


func test_oscillate_stat_changes_value_over_time() -> void:
	var effect := _make_oscillation_effect(0.1)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var base_value: float = GameRules.base.ball_speed_offset
	var found_different := false
	for frame_index in range(60):
		_manager.process_frame(0.016)

		if not is_equal_approx(
			Stats.resolve(GameRules.base.ball_speed_offset, &"ball_speed_offset", _manager),
			base_value
		):
			found_different = true
			break

	assert_true(found_different, "Oscillation should change stat value within 60 frames")


func test_unregister_stops_oscillation() -> void:
	var effect := _make_oscillation_effect(0.1)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var base_value: float = GameRules.base.ball_speed_offset
	var observed_active := false
	for frame_index in range(60):
		_manager.process_frame(0.016)
		var current: float = Stats.resolve(base_value, &"ball_speed_offset", _manager)
		if not is_equal_approx(current, base_value):
			observed_active = true
			break

	# Tautology guard: a stubbed-no-op apply() would never produce a different value, so this
	# assertion is what makes the post-unregister equality below meaningful.
	assert_true(observed_active, "Oscillation should have shifted the stat before unregister")

	_manager.unregister_source(item)

	assert_eq(
		Stats.resolve(base_value, &"ball_speed_offset", _manager),
		base_value,
	)
