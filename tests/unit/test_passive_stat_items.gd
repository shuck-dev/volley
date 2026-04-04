extends GutTest

# Verifies that all passive stat modifier items (always trigger + modify_stat outcome)
# load and apply correctly through the effect system.

var _items: Array[ItemDefinition] = [
	preload("res://resources/items/ankle_weights.tres"),
	preload("res://resources/items/grip_tape.tres"),
	preload("res://resources/items/training_ball.tres"),
	preload("res://resources/items/court_lines.tres"),
]


func _create_manager(item: ItemDefinition) -> Node:
	var manager: Node = ItemFactory.create_manager(self, item.key)
	manager.items.assign([item])
	return manager


func _stat_key(item: ItemDefinition) -> StringName:
	var outcome: ModifyStatOutcome = item.effects[0].outcomes[0]
	return outcome.stat_key


func _value_per_level(item: ItemDefinition) -> float:
	var outcome: ModifyStatOutcome = item.effects[0].outcomes[0]
	return outcome.value


# --- loads ---
func test_all_items_load_with_key_and_effects() -> void:
	for item in _items:
		assert_ne(item.key, "", "%s should have a key" % item.resource_path)
		assert_gt(item.effects.size(), 0, "%s should have effects" % item.key)


# --- no effect before purchase ---
func test_no_effect_before_purchase() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		assert_eq(
			manager.get_stat(stat),
			GameRules.BASE_STATS[stat],
			"%s should not modify %s before purchase" % [item.key, stat],
		)


# --- applies at level one ---
func test_applies_stat_at_level_one() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		var delta := _value_per_level(item)
		manager._progression.friendship_point_balance = 100000
		manager.purchase(item.key)
		assert_eq(
			manager.get_stat(stat),
			GameRules.BASE_STATS[stat] + delta,
			"%s should add %s to %s at level 1" % [item.key, delta, stat],
		)


# --- stacks linearly ---
func test_stacks_linearly_across_levels() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		var delta := _value_per_level(item)
		manager._progression.friendship_point_balance = 100000
		manager.purchase(item.key)
		manager.purchase(item.key)
		manager.purchase(item.key)
		assert_eq(
			manager.get_stat(stat),
			GameRules.BASE_STATS[stat] + (delta * 3),
			"%s should stack linearly at level 3" % item.key,
		)
