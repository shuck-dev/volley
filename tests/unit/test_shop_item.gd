extends GutTest


class TestShopItemDisplay:
	extends GutTest

	const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

	var _item: ShopItem
	var _definition: ItemDefinition
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_definition = _item_manager.items[0]
		_item = ShopItemScene.instantiate()
		_item._item_manager = _item_manager
		_item.setup(_definition)
		add_child_autofree(_item)

	func test_displays_item_name() -> void:
		assert_eq(_item.tooltip.name_label.text, _definition.display_name)

	func test_displays_cost_when_not_taken() -> void:
		var expected_cost: int = _item_manager.calculate_cost(_definition.key)
		assert_eq(_item.tooltip.cost_label.text, "%d FP" % expected_cost)

	func test_tooltip_hidden_by_default() -> void:
		assert_false(_item.tooltip.visible)


class TestShopPanelLayout:
	extends GutTest

	const ShopScene: PackedScene = preload("res://scenes/shop.tscn")

	var _panel: ShopPanel
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_panel = ShopScene.instantiate()
		_panel._item_manager = _item_manager
		add_child_autofree(_panel)

	func test_spawns_visible_items() -> void:
		var container: Node2D = _panel.get_node("ItemContainer")
		assert_gt(container.get_child_count(), 0)

	func test_friendship_label_shows_current_balance() -> void:
		var expected_balance: int = _item_manager.get_friendship_point_balance()
		assert_eq(_panel.friendship_label.text, "Friendship: %d" % expected_balance)
