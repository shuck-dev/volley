extends GutTest

var _item: ItemDefinition


func before_each() -> void:
	_item = ItemDefinition.new()
	_item.max_level = 3


func _make_effect(min_level: int, max_level: Variant) -> Effect:
	var effect := Effect.new()
	effect.min_active_level = min_level
	effect.max_active_level = max_level
	return effect


# --- get_effects_for_level ---
func test_returns_effect_active_at_exact_min_level() -> void:
	var effect := _make_effect(1, null)
	_item.effects = [effect]
	assert_eq(_item.get_effects_for_level(1).size(), 1)


func test_returns_effect_active_within_range() -> void:
	var effect := _make_effect(1, 2)
	_item.effects = [effect]
	assert_eq(_item.get_effects_for_level(2).size(), 1)


func test_excludes_effect_below_min_level() -> void:
	var effect := _make_effect(2, null)
	_item.effects = [effect]
	assert_eq(_item.get_effects_for_level(1).size(), 0)


func test_excludes_effect_above_max_level() -> void:
	var effect := _make_effect(1, 2)
	_item.effects = [effect]
	assert_eq(_item.get_effects_for_level(3).size(), 0)


func test_null_max_active_level_uses_item_max_level() -> void:
	var effect := _make_effect(1, null)
	_item.effects = [effect]
	assert_eq(_item.get_effects_for_level(3).size(), 1)


func test_null_max_active_level_excludes_beyond_item_max_level() -> void:
	var effect := _make_effect(1, null)
	_item.effects = [effect]
	assert_eq(_item.get_effects_for_level(4).size(), 0)


func test_returns_multiple_effects_when_all_active() -> void:
	_item.effects = [_make_effect(1, null), _make_effect(2, null)]
	assert_eq(_item.get_effects_for_level(2).size(), 2)


func test_returns_only_effects_active_at_level() -> void:
	_item.effects = [_make_effect(1, 1), _make_effect(2, null)]
	assert_eq(_item.get_effects_for_level(2).size(), 1)


func test_returns_empty_when_no_effects_defined() -> void:
	_item.effects = []
	assert_eq(_item.get_effects_for_level(1).size(), 0)


# --- standard_ball.tres data checks ---
func test_standard_ball_tres_has_consolidation_fields() -> void:
	var ball: ItemDefinition = load("res://resources/items/standard_ball.tres")
	assert_eq(ball.consolidations_to_l2, 5, "consolidations_to_l2 should be 5")
	assert_eq(ball.consolidations_to_l3, 10, "consolidations_to_l3 should be 10")
	assert_eq(ball.upgrade_cost, 50, "upgrade_cost should be 50")
	assert_eq(
		ball.consolidation_release_multiplier,
		0.5,
		"consolidation_release_multiplier should be 0.5",
	)
	assert_gt(ball.effects.size(), 0, "should have at least one effect")
	assert_eq(
		ball.effects[0].trigger.type,
		&"on_consolidation",
		"first effect trigger should be on_consolidation",
	)
	assert_gt(ball.effects[0].outcomes.size(), 0, "effect should have at least one outcome")
