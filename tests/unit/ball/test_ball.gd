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
func test_increase_speed_advances_tier_at_ceiling() -> void:
	_ball.current_tier = 0
	_ball.speed = _ball.tier_ceiling - 1.0
	_ball.increase_speed()
	assert_eq(_ball.current_tier, 1, "crossing the ceiling steps up a tier")
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01, "speed drops to the new tier's floor")


# --- reset_speed ---
func test_reset_speed_returns_to_tier_zero_floor() -> void:
	_ball.current_tier = 2
	_ball.speed = _ball.tier_ceiling
	_ball.reset_speed()
	assert_eq(_ball.current_tier, 0, "miss resets to Tier 0")
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01)


# --- set_speed_for_streak ---
func test_set_speed_for_streak_zero_equals_tier_floor() -> void:
	_ball.current_tier = 0
	_ball.set_speed_for_streak(0)
	assert_almost_eq(_ball.speed, _ball.tier_floor, 0.01)


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
