extends GutTest

# Tests for ball speed behaviour driven by item manager stat values.
# Injects a real ItemManager with mock storage to avoid autoload dependency.

var _ball: Ball
var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	(
		_manager
		. items
		. assign(
			[
				preload("res://resources/items/training_ball.tres"),
				preload("res://resources/items/court_lines.tres"),
			]
		)
	)
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)
	_ball.linear_velocity = Vector2(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager), 0.0
	)


# --- increase_speed ---
func test_increase_speed_adds_increment() -> void:
	_ball.current_tier = 0
	_ball.speed = _ball.tier_floor
	_ball.increase_speed()
	var expected: float = (
		_ball.tier_floor
		+ Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager)
	)
	assert_almost_eq(_ball.speed, expected, 0.01)


func test_increase_speed_advances_tier_at_ceiling() -> void:
	_ball.current_tier = 0
	_ball.speed = _ball.tier_ceiling - 1.0
	_ball.increase_speed()
	assert_eq(_ball.current_tier, 1, "crossing the ceiling steps up a tier")
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01, "speed drops to the new tier's floor")


func test_increase_speed_never_exceeds_tier_ceiling() -> void:
	_ball.current_tier = 0
	var ceiling: float = _ball.tier_ceiling
	_ball.speed = ceiling - 1.0
	_ball.increase_speed()
	assert_true(_ball.speed <= ceiling + 0.01, "speed stays within the band's ceiling")


# --- reset_speed ---
func test_reset_speed_returns_to_tier_zero_floor() -> void:
	_ball.current_tier = 2
	_ball.speed = _ball.tier_ceiling
	_ball.reset_speed()
	assert_eq(_ball.current_tier, 0, "miss resets to Tier 0")
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01)


func test_reset_speed_preserves_direction() -> void:
	_ball.linear_velocity = Vector2(0.0, 500.0)
	_ball.reset_speed()
	assert_almost_eq(_ball.linear_velocity.x, 0.0, 0.01)
	assert_gt(_ball.linear_velocity.y, 0.0)


# --- per-frame clamp against the active tier band ---
func test_effect_processor_clamps_speed_to_tier_band() -> void:
	_ball.current_tier = 0
	_ball.speed = _ball.tier_ceiling + 500.0
	_ball.effect_processor.sync_base_speed()
	_ball._physics_process(0.016)
	assert_true(_ball.speed <= _ball.tier_ceiling + 0.01, "frame clamp holds the tier ceiling")


func test_effect_processor_clamp_floor_is_tier_floor() -> void:
	_ball.current_tier = 1
	_ball.speed = 0.0
	_ball.effect_processor.sync_base_speed()
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01, "frame clamp lifts to the tier floor")


# --- set_speed_for_streak ---
func test_set_speed_for_streak_zero_equals_tier_floor() -> void:
	_ball.current_tier = 0
	_ball.set_speed_for_streak(0)
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01)


func test_set_speed_for_streak_matches_incremental_hits() -> void:
	_ball.current_tier = 0
	_ball.speed = _ball.tier_floor
	var increment: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager
	)
	var hits := 3
	var expected_speed: float = _ball.tier_floor + hits * increment

	_ball.set_speed_for_streak(hits)

	assert_almost_eq(_ball.speed, expected_speed, 0.01)


func test_set_speed_for_streak_caps_at_tier_ceiling() -> void:
	_ball.current_tier = 0
	_ball.set_speed_for_streak(9999)
	assert_almost_eq(_ball.speed, _ball.tier_ceiling, 0.01)


# --- miss zone registration ---
func test_miss_zone_entry_emits_missed() -> void:
	var zone := MissZone.new()
	add_child_autofree(zone)
	_ball.register_miss_zone(zone)
	watch_signals(_ball)

	zone.body_entered.emit(_ball)

	assert_signal_emitted(_ball, "missed")


func test_miss_zone_ignores_other_bodies() -> void:
	var zone := MissZone.new()
	add_child_autofree(zone)
	_ball.register_miss_zone(zone)
	watch_signals(_ball)

	var other_body: Node2D = Node2D.new()
	add_child_autofree(other_body)
	zone.body_entered.emit(other_body)

	assert_signal_not_emitted(_ball, "missed")


func test_register_miss_zone_is_idempotent() -> void:
	var zone := MissZone.new()
	add_child_autofree(zone)
	_ball.register_miss_zone(zone)
	_ball.register_miss_zone(zone)
	watch_signals(_ball)

	zone.body_entered.emit(_ball)

	assert_signal_emit_count(_ball, "missed", 1)

# Future pin of the speed clamp invariant should route through production
# _apply_speed_offset with a known _base_speed, not a tautological re-clampf.
