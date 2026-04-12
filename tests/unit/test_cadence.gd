extends GutTest

# Verifies Cadence item: ball speed oscillation and ceiling raise on max speed reached.
# Effect 1: always -> oscillate_stat(ball_speed_offset)
# Effect 2: on_max_speed_reached -> modify_stat_until_miss(ball_speed_max_range)

var _item: ItemDefinition
var _manager: Node


func before_each() -> void:
	_item = preload("res://resources/items/cadence.tres")
	_manager = ItemFactory.create_manager(self, _item.key)
	_manager.items.assign([_item])


func _purchase() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("cadence")


# --- resource definition ---
func test_item_loads_with_correct_key() -> void:
	assert_eq(_item.key, "cadence")


func test_item_has_two_effects() -> void:
	assert_eq(_item.effects.size(), 2)


func test_base_cost_matches_design() -> void:
	assert_eq(_item.base_cost, 85)


func test_cost_scaling_matches_design() -> void:
	assert_almost_eq(_item.cost_scaling, 1.5, 0.01)


# --- oscillation (effect 1) ---
func test_oscillation_active_after_purchase() -> void:
	_purchase()

	var base_value: float = GameRules.base_stats[&"ball_speed_offset"]
	var found_different := false
	for frame_index in range(60):
		_manager._effect_manager.process_frame(0.016)
		if not is_equal_approx(_manager.get_stat(&"ball_speed_offset"), base_value):
			found_different = true
			break

	assert_true(found_different, "ball_speed_offset should oscillate after purchasing Cadence")


func test_oscillation_inactive_before_purchase() -> void:
	for frame_index in range(60):
		_manager._effect_manager.process_frame(0.016)

	assert_eq(
		_manager.get_stat(&"ball_speed_offset"),
		GameRules.base_stats[&"ball_speed_offset"],
	)


# --- ceiling raise (effect 2) ---
func test_ceiling_raises_on_max_speed_reached() -> void:
	_purchase()

	_manager._effect_manager.process_event(&"on_max_speed_reached")

	assert_gt(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.base_stats[&"ball_speed_max_range"],
	)


func test_ceiling_raise_stacks() -> void:
	_purchase()
	var base_range: float = GameRules.base_stats[&"ball_speed_max_range"]

	_manager._effect_manager.process_event(&"on_max_speed_reached")
	var after_first: float = _manager.get_stat(&"ball_speed_max_range")

	_manager._effect_manager.process_event(&"on_max_speed_reached")
	var after_second: float = _manager.get_stat(&"ball_speed_max_range")

	assert_gt(after_first, base_range)
	assert_gt(after_second, after_first)


func test_ceiling_raise_clears_on_miss() -> void:
	_purchase()
	_manager._effect_manager.process_event(&"on_max_speed_reached")
	_manager._effect_manager.process_event(&"on_max_speed_reached")

	_manager._effect_manager.process_event(&"on_miss")

	assert_eq(
		_manager.get_stat(&"ball_speed_max_range"),
		GameRules.base_stats[&"ball_speed_max_range"],
	)


func test_higher_level_raises_ceiling_more() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("cadence")
	_manager._effect_manager.process_event(&"on_max_speed_reached")
	var level_one_raise: float = (
		_manager.get_stat(&"ball_speed_max_range") - GameRules.base_stats[&"ball_speed_max_range"]
	)

	_manager._effect_manager.process_event(&"on_miss")
	_manager.purchase("cadence")
	_manager._effect_manager.process_event(&"on_max_speed_reached")
	var level_two_raise: float = (
		_manager.get_stat(&"ball_speed_max_range") - GameRules.base_stats[&"ball_speed_max_range"]
	)

	assert_gt(level_two_raise, level_one_raise)
