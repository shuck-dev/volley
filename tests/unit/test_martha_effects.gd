extends GutTest

# Verifies halve_streak game action: on miss with halve_streak active,
# volley count halves and ball speed matches the halved streak position.

@warning_ignore("shadowed_global_identifier")
const HalveStreakOutcome = preload("res://scripts/items/effect/outcomes/halve_streak_outcome.gd")
const MARTHA_RESOURCE: Resource = preload("res://resources/partners/martha.tres")

var _game: Node2D
var _ball_stub: Ball
var _paddle_stub: Paddle
var _autoplay_controller_stub: AutoplayController
var _item_manager: Node
var _last_volley_count := -1


func before_each() -> void:
	_ball_stub = load("res://tests/stubs/ball_stub.gd").new()
	_paddle_stub = load("res://tests/stubs/paddle_stub.gd").new()

	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_item_manager = load("res://scripts/items/item_manager.gd").new()
	_item_manager._progression = ProgressionData.new(mock_storage)
	_item_manager._effect_manager = EffectManager.new()
	add_child_autofree(_item_manager)

	_autoplay_controller_stub = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(_autoplay_controller_stub)

	_game = load("res://scripts/core/game.gd").new()
	_game.ball = _ball_stub
	_game.player_paddle = _paddle_stub
	_game.autoplay_controller = _autoplay_controller_stub
	_game._progression = ProgressionData.new(mock_storage)
	_game._progression_config = ProgressionConfig.new()
	_game._item_manager = _item_manager
	add_child_autofree(_ball_stub)
	add_child_autofree(_paddle_stub)
	add_child_autofree(_game)

	_game.volley_count_changed.connect(func(count: int) -> void: _last_volley_count = count)


func _hit() -> void:
	_paddle_stub.paddle_hit.emit()


func _register_halve_streak() -> void:
	var outcome := HalveStreakOutcome.new()

	var trigger := Trigger.new()
	trigger.type = &"on_miss"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := ItemDefinition.new()
	item.key = "halve_streak_source"
	item.max_level = 1
	item.effects = [effect]
	_item_manager._effect_manager.register_source(item, 1)


# --- halve_streak on miss ---
func test_halve_streak_halves_volley_count_on_miss() -> void:
	for hit_index in range(10):
		_hit()
	_register_halve_streak()

	_ball_stub.missed.emit()

	assert_eq(_last_volley_count, 5)


func test_halve_streak_floors_odd_count() -> void:
	for hit_index in range(7):
		_hit()
	_register_halve_streak()

	_ball_stub.missed.emit()

	assert_eq(_last_volley_count, 3)


func test_without_halve_streak_volley_resets_to_zero() -> void:
	for hit_index in range(10):
		_hit()

	_ball_stub.missed.emit()

	assert_eq(_last_volley_count, 0)


func test_halve_streak_on_single_volley_halves_to_zero() -> void:
	_hit()
	_register_halve_streak()

	_ball_stub.missed.emit()

	assert_eq(_last_volley_count, 0)


# --- martha resource ---
func test_martha_resource_has_two_effects() -> void:
	var martha: Resource = MARTHA_RESOURCE
	assert_eq(martha.effects.size(), 2)


func test_martha_fp_effect_is_always_percentage() -> void:
	var martha: Resource = MARTHA_RESOURCE
	var fp_effect: Effect = martha.effects[0]
	assert_eq(fp_effect.trigger.type, &"always")
	var outcome: StatOutcome = fp_effect.outcomes[0] as StatOutcome
	assert_not_null(outcome)
	assert_eq(outcome.stat_key, &"friendship_points_per_hit")
	assert_eq(outcome.operation, &"percentage")
	assert_almost_eq(outcome.value, 0.25, 0.001)


func test_martha_halve_streak_effect_is_on_miss() -> void:
	var martha: Resource = MARTHA_RESOURCE
	var halve_effect: Effect = martha.effects[1]
	assert_eq(halve_effect.trigger.type, &"on_miss")
	assert_true(halve_effect.outcomes[0] is HalveStreakOutcome)


# --- register/unregister on activate/deactivate ---
func test_activate_partner_registers_effects() -> void:
	var martha: Resource = MARTHA_RESOURCE
	_item_manager._effect_manager.register_source(martha, 1)

	var fp_stat: float = _item_manager.get_stat(&"friendship_points_per_hit")
	var base_fp: float = GameRules.base_stats[&"friendship_points_per_hit"]

	assert_almost_eq(fp_stat, base_fp * 1.25, 0.001)


func test_deactivate_partner_unregisters_effects() -> void:
	var martha: Resource = MARTHA_RESOURCE
	_item_manager._effect_manager.register_source(martha, 1)
	_item_manager._effect_manager.unregister_source(martha)

	var fp_stat: float = _item_manager.get_stat(&"friendship_points_per_hit")
	var base_fp: float = GameRules.base_stats[&"friendship_points_per_hit"]

	assert_almost_eq(fp_stat, base_fp, 0.001)
