extends GutTest

# Verifies OscillateStatOutcome: continuous per-frame oscillation, amplitude bounds,
# level scaling, and unregister stopping the effect.

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


func _worst_absolute_offset_over_period(base_value: float) -> float:
	var step_count := 32
	var period: float = TAU / StatOscillation.PRIMARY_FREQUENCY
	var delta: float = period / float(step_count)
	var worst := 0.0
	for i in range(step_count):
		_manager.process_frame(delta)
		var current: float = Stats.resolve(base_value, &"ball_speed_offset", _manager)
		worst = maxf(worst, absf(current - base_value))
	return worst


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


# Sweeps the manager one slow-period and asserts the worst |offset| sits inside the amplitude bound.
# Replaces a 300-iteration `process_frame` Monte Carlo whose upper-bound assertion was satisfied
# by a stubbed-no-op apply() (offset never deviates from base, trivially within bounds).
func test_oscillate_stat_stays_within_amplitude() -> void:
	var amplitude := 0.25
	var effect := _make_oscillation_effect(amplitude)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var range_value: float = GameRules.base.ball_speed_max_range
	var effective_amplitude: float = amplitude * range_value
	var base_value: float = GameRules.base.ball_speed_offset
	var extreme: float = _worst_absolute_offset_over_period(base_value)

	assert_true(
		extreme <= effective_amplitude + 0.0001,
		"Worst |offset| %f should be <= effective amplitude %f" % [extreme, effective_amplitude],
	)
	# Tautology guard: a no-op apply() would never register the oscillation; assert the sampled
	# extremum actually approaches the bound so the upper assertion has teeth.
	assert_true(
		extreme >= effective_amplitude * 0.5,
		"Worst |offset| %f should approach the amplitude bound %f" % [extreme, effective_amplitude],
	)


# Same shape as the level-1 amplitude test; verifies level scaling doubles the effective bound.
# Pre-rewrite per-frame range assertion was satisfied by a stubbed no-op (value stays at base,
# inside any non-degenerate range), so the bound was never actually exercised.
func test_oscillate_stat_scales_range_by_level() -> void:
	var amplitude := 0.25
	var effect := _make_oscillation_effect(amplitude)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 2)

	var range_value: float = GameRules.base.ball_speed_max_range
	var effective_amplitude: float = amplitude * 2.0 * range_value
	var base_value: float = GameRules.base.ball_speed_offset
	var extreme: float = _worst_absolute_offset_over_period(base_value)

	assert_true(
		extreme <= effective_amplitude + 0.0001,
		(
			"Worst |offset| %f at level 2 should be <= effective amplitude %f"
			% [extreme, effective_amplitude]
		),
	)
	assert_true(
		extreme >= effective_amplitude * 0.5,
		(
			"Worst |offset| %f should approach the doubled level-2 bound %f"
			% [extreme, effective_amplitude]
		),
	)


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
