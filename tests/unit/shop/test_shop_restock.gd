extends GutTest

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")

var _manager: Node
var _shop: Node


func before_each() -> void:
	_manager = _make_manager_with_balls()
	_shop = ShopScene.instantiate()
	_shop._item_manager = _manager
	add_child_autofree(_shop)


func test_first_restock_is_free() -> void:
	var balance_before: int = _manager.economy.soul_balance
	_shop.restock()
	assert_eq(_manager.economy.soul_balance, balance_before, "first restock deducts no soul")
	assert_eq(_shop._refresh_count, 1, "refresh count incremented")


func test_second_restock_costs_soul() -> void:
	_manager.add_soul(500)
	_shop._refresh_count = 1
	var balance_before: int = _manager.economy.soul_balance
	_shop.restock()
	assert_lt(_manager.economy.soul_balance, balance_before, "soul deducted after first restock")


func test_restock_replaces_item_nodes() -> void:
	_manager.add_soul(500)
	_shop._refresh_count = 1
	var before_nodes: Array[Node] = _shop.items_anchor.get_children()
	_shop.restock()
	var after_nodes: Array[Node] = _shop.items_anchor.get_children()
	for node in after_nodes:
		assert_false(before_nodes.has(node), "restock replaces all item nodes")


func _make_manager_with_balls() -> Node:
	var manager: Node = ItemFactory.create_manager(
		self, "test_ball_a", &"ball_speed_min", &"add", 10.0
	)
	var definitions: Array[ItemDefinition] = []
	for key in ["test_ball_a", "test_ball_b", "test_ball_c"]:
		var definition: ItemDefinition = ItemFactory.create(key, &"ball_speed_min", &"add", 10.0)
		definition.role = &"ball"
		definition.base_cost = 10
		definitions.append(definition)
	manager.items.assign(definitions)
	manager.economy.soul_balance = 500
	return manager
