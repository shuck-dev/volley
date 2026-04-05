extends GutTest


class TestShopItemDisplay:
	extends GutTest

	const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

	var _item: ShopItem
	var _definition: ItemDefinition

	func before_each() -> void:
		_definition = ItemManager.items[0]
		_item = ShopItemScene.instantiate()
		_item.setup(_definition)
		add_child_autofree(_item)

	func test_displays_item_name() -> void:
		assert_eq(_item.name_label.text, _definition.display_name)

	func test_displays_cost_as_friendship_points() -> void:
		var expected_cost: int = ItemManager.calculate_cost(_definition.key)
		assert_eq(_item.cost_label.text, "%d FP" % expected_cost)

	func test_shows_taken_when_maxed() -> void:
		var original_level: int = ItemManager.get_level(_definition.key)
		var levels_needed: int = _definition.max_level - original_level
		ItemManager.add_friendship_points(100000)
		for level: int in levels_needed:
			ItemManager.purchase(_definition.key)
		assert_eq(_item.cost_label.text, "Taken")
		# Restore state
		for level: int in levels_needed:
			ItemManager.remove_level(_definition.key)
		ItemManager.subtract_friendship_points(100000)

	func test_no_crash_without_setup() -> void:
		var bare_item: ShopItem = ShopItemScene.instantiate()
		add_child_autofree(bare_item)
		assert_eq(bare_item.name_label.text, "Item Name")


class TestShopPanelLayout:
	extends GutTest

	const ShopScene: PackedScene = preload("res://scenes/shop.tscn")

	func test_spawns_up_to_slot_limit() -> void:
		var panel: ShopPanel = ShopScene.instantiate()
		add_child_autofree(panel)
		var container: Node2D = panel.get_node("ItemContainer")
		assert_lte(container.get_child_count(), ShopPanel.SLOTS)
		assert_gt(container.get_child_count(), 0)

	func test_items_positioned_within_panel_width() -> void:
		var panel: ShopPanel = ShopScene.instantiate()
		add_child_autofree(panel)
		var container: Node2D = panel.get_node("ItemContainer")
		for child: Node in container.get_children():
			var shop_item: ShopItem = child as ShopItem
			assert_gte(shop_item.position.x, 0.0, "item should not be left of panel")
			assert_lt(
				shop_item.position.x, float(panel.preferred_width), "item should be within panel"
			)

	func test_items_evenly_spaced() -> void:
		var panel: ShopPanel = ShopScene.instantiate()
		add_child_autofree(panel)
		var container: Node2D = panel.get_node("ItemContainer")
		if container.get_child_count() < 2:
			pass_test("not enough items to check spacing")
			return
		var first_gap: float = container.get_child(1).position.x - container.get_child(0).position.x
		for index: int in range(2, container.get_child_count()):
			var gap: float = (
				container.get_child(index).position.x - container.get_child(index - 1).position.x
			)
			assert_almost_eq(gap, first_gap, 0.01, "spacing should be consistent")

	func test_friendship_label_shows_current_balance() -> void:
		var panel: ShopPanel = ShopScene.instantiate()
		add_child_autofree(panel)
		var expected_balance: int = ItemManager.get_friendship_point_balance()
		assert_eq(panel.friendship_label.text, "Friendship: %d" % expected_balance)

	func test_friendship_label_updates_on_balance_change() -> void:
		var panel: ShopPanel = ShopScene.instantiate()
		add_child_autofree(panel)
		ItemManager.add_friendship_points(1)
		var expected_balance: int = ItemManager.get_friendship_point_balance()
		assert_eq(panel.friendship_label.text, "Friendship: %d" % expected_balance)
		ItemManager.subtract_friendship_points(1)
