extends GutTest

var _item: ItemDefinition
var _manager: Node
var _value_per_level: float


func before_each() -> void:
	_item = preload("res://resources/items/ankle_weights.tres")
	_value_per_level = _item.effects[0].outcomes[0].parameters[&"value"]
	_manager = ItemFactory.create_manager(self, _item.key)
	_manager.items.assign([_item])


# --- stat application ---
func test_no_effect_before_purchase() -> void:
	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.BASE_STATS[&"paddle_speed"])


func test_applies_paddle_speed_at_level_one() -> void:
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase("ankle_weights")
	var expected: float = GameRules.BASE_STATS[&"paddle_speed"] + _value_per_level
	assert_eq(_manager.get_stat(&"paddle_speed"), expected)


func test_stacks_linearly_with_level() -> void:
	_manager._progression.friendship_point_balance = 10000
	_manager.purchase("ankle_weights")
	_manager.purchase("ankle_weights")
	_manager.purchase("ankle_weights")
	var expected: float = GameRules.BASE_STATS[&"paddle_speed"] + (_value_per_level * 3)
	assert_eq(_manager.get_stat(&"paddle_speed"), expected)
