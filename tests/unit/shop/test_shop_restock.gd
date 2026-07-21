extends GutTest

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")

var _manager: Node
var _shop: Node


func before_each() -> void:
	_manager = _make_manager_with_balls()
	_shop = ShopScene.instantiate()
	_shop._item_manager = _manager
	_shop._refresh_count = 0
	add_child_autofree(_shop)
	_shop._update_restock_button()


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


func test_restock_cost_scales_with_displayed_item_base_costs() -> void:
	_manager.add_soul(500)
	_shop._refresh_count = 1
	var cost: int = _shop._calculate_restock_cost()
	var total_base: int = 0
	for child in _shop.items_anchor.get_children():
		var si: ShopItem = child as ShopItem
		if si != null and si.item_definition != null:
			total_base += si.item_definition.base_cost
	var expected: int = max(1, ceili(total_base * _shop.config.restock_cost_multiplier))
	assert_eq(cost, expected, "cost scales with displayed items' base costs")


func test_restock_refuses_when_broke() -> void:
	_manager.economy.soul_balance = 0
	_shop._refresh_count = 1
	assert_eq(_shop._refresh_count, 1)
	var child_count_before: int = _shop.items_anchor.get_child_count()
	_shop.restock()
	assert_eq(_shop._refresh_count, 1, "refresh count unchanged when broke")
	assert_eq(
		_shop.items_anchor.get_child_count(),
		child_count_before,
		"items not cleared when restock refused"
	)


func test_restock_button_shows_free_initially() -> void:
	assert_not_null(_shop.restock_button, "restock_button assigned")
	assert_eq(_shop.restock_button.text, "Restock (Free)")


func test_restock_button_updates_after_restock() -> void:
	_manager.add_soul(500)
	_shop.restock()
	assert_string_contains(
		_shop.restock_button.text, "Soul", "button shows soul cost after first restock"
	)


func test_restock_button_disabled_when_broke() -> void:
	_manager.economy.soul_balance = 0
	_shop._refresh_count = 1
	_shop._update_restock_button()
	assert_true(_shop.restock_button.disabled, "button disabled when broke")


func test_restock_button_enabled_when_affordable() -> void:
	_manager.add_soul(500)
	_shop._refresh_count = 1
	_shop._update_restock_button()
	assert_false(_shop.restock_button.disabled, "button enabled when affordable")


func test_refresh_count_label_shows_count() -> void:
	assert_not_null(_shop.refresh_count_label, "refresh_count_label assigned")
	assert_eq(_shop.refresh_count_label.text, "Refresh: 0")
	_shop.restock()
	assert_eq(_shop.refresh_count_label.text, "Refresh: 1")


func test_calculate_restock_cost_returns_zero_for_first_refresh() -> void:
	_shop._refresh_count = 0
	assert_eq(_shop._calculate_restock_cost(), 0)


func test_clear_items_removes_all_children() -> void:
	_shop.restock()
	assert_gt(_shop.items_anchor.get_child_count(), 0, "items exist before clear")
	_shop._clear_items()
	assert_eq(_shop.items_anchor.get_child_count(), 0, "all items removed after clear")


func test_restock_replaces_item_nodes() -> void:
	_manager.add_soul(500)
	_shop._refresh_count = 1
	var before_nodes: Array[Node] = _shop.items_anchor.get_children()
	_shop.restock()
	var after_nodes: Array[Node] = _shop.items_anchor.get_children()
	var any_same: bool = false
	for n in after_nodes:
		if before_nodes.has(n):
			any_same = true
			break
	assert_false(any_same, "restock replaces all item nodes with new instances")


func test_restock_works_for_pool_larger_than_slots() -> void:
	# Create a shop with pool > display_slots to guarantee a visible change.
	_manager.add_soul(500)
	_shop.config.display_slots = 2
	_shop._refresh_count = 1
	_shop._clear_items()
	_shop._spawn_items()
	var before_keys: Array[String] = _get_item_keys()

	_shop.restock()
	var after_keys: Array[String] = _get_item_keys()

	assert_ne(
		before_keys, after_keys, "restock changes the visible subset when pool exceeds slot count"
	)


func _get_item_keys() -> Array[String]:
	var keys: Array[String] = []
	for child: Node in _shop.items_anchor.get_children():
		var si: ShopItem = child as ShopItem
		if si != null and si.item_definition != null:
			keys.append(si.item_definition.key)
	return keys


## Creates an ItemManager with several ball items so restock has a pool to shuffle.
func _make_manager_with_balls() -> Node:
	var ball_keys := ["test_ball_a", "test_ball_b", "test_ball_c", "test_ball_d", "test_ball_e"]
	var ball_costs := [10, 20, 30, 40, 50]

	# Use the first key for the initial manager item; we replace items immediately after.
	var manager: Node = ItemFactory.create_manager(
		self, ball_keys[0], &"ball_speed_min", &"add", 10.0
	)

	var definitions: Array[ItemDefinition] = []
	for i in ball_keys.size():
		var def: ItemDefinition = ItemFactory.create(ball_keys[i], &"ball_speed_min", &"add", 10.0)
		def.role = &"ball"
		def.base_cost = ball_costs[i]
		definitions.append(def)

	manager.items.assign(definitions)
	manager.economy.soul_balance = 500
	return manager
