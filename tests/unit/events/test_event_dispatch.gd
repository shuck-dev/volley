extends GutTest

# Verifies the event-based causality system: event dispatch, modify_stat_until_miss,
# and oscillate_stat outcomes.

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
	trigger.type = &"on_max_speed_reached"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1
	return effect


## Sweeps the manager forward one slow-period of oscillation (TAU / PRIMARY_FREQUENCY ~= 3.7s)
## at 32 deterministic steps and returns the worst absolute deviation from `base_value`.
## Uses the production `process_frame` / `Stats.resolve` path so a stubbed-no-op apply() leaves
## the offset at 0 and the caller's tautology guard fails.
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


# --- event dispatch ---
func test_process_event_fires_matching_trigger() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_max_speed_reached")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 30.0,
	)


func test_process_event_ignores_non_matching_trigger() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_hit")

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

	_manager.process_event(&"on_max_speed_reached")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 60.0,
	)


# --- modify_stat_until_miss ---
func test_modify_stat_until_miss_stacks_on_repeated_events() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	_manager.process_event(&"on_max_speed_reached")
	_manager.process_event(&"on_max_speed_reached")
	_manager.process_event(&"on_max_speed_reached")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 90.0,
	)


func test_miss_event_clears_until_miss_modifiers() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_max_speed_reached")
	_manager.process_event(&"on_max_speed_reached")

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
	_manager.process_event(&"on_max_speed_reached")

	_manager.process_event(&"on_miss")

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range + 50.0,
	)


func test_unregister_removes_event_effects() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)
	_manager.process_event(&"on_max_speed_reached")

	_manager.unregister_source(item)

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_max_range, &"ball_speed_max_range", _manager),
		GameRules.base.ball_speed_max_range,
	)


# --- oscillate_stat ---
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


# --- game action return path ---
func test_process_event_returns_empty_array_when_no_game_actions() -> void:
	var effect := _make_until_miss_effect(&"ball_speed_max_range", &"add", 30.0)
	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	var actions: Array[StringName] = _manager.process_event(&"on_max_speed_reached")

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


# --- halve_streak outcome ---
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
