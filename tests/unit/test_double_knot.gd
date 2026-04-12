extends GutTest

# Double Knot has a level-gated effect: return_angle_influence activates at level 2+.

var _item: ItemDefinition
var _manager: Node


func before_each() -> void:
	_item = preload("res://resources/items/double_knot.tres")
	_manager = ItemFactory.create_manager(self, _item.key)
	_manager.items.assign([_item])


# --- level-gated effect ---
func test_return_angle_influence_inactive_at_level_one() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")
	assert_eq(
		_manager.get_stat(&"return_angle_influence"),
		GameRules.base_stats[&"return_angle_influence"],
	)


func test_return_angle_influence_active_at_level_two() -> void:
	_manager._progression.friendship_point_balance = 100000
	_manager.purchase("double_knot")
	_manager.purchase("double_knot")
	assert_gt(
		_manager.get_stat(&"return_angle_influence"),
		GameRules.base_stats[&"return_angle_influence"],
	)
