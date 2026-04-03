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
