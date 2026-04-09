extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")


class TestShopItemDisplay:
	extends GutTest

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


class TestShopItemContract:
	extends GutTest

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

	func test_can_be_taken_returns_false_without_definition() -> void:
		var bare_item: ShopItem = ShopItemScene.instantiate()
		bare_item._item_manager = _item_manager
		add_child_autofree(bare_item)
		assert_false(bare_item.can_be_taken())

	func test_can_be_taken_returns_false_when_balance_too_low() -> void:
		_item_manager._progression.friendship_point_balance = 0
		assert_false(_item.can_be_taken())

	func test_can_be_taken_returns_true_when_affordable_and_unowned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		assert_true(_item.can_be_taken())

	func test_can_be_taken_returns_false_when_already_owned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.can_be_taken())

	func test_build_drag_payload_returns_definition() -> void:
		assert_eq(_item.build_drag_payload(), _definition)


class TestShopItemTakenState:
	extends GutTest

	var _definition: ItemDefinition
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager._progression.friendship_point_balance = 1000
		_definition = _item_manager.items[0]

	func _make_item(definition: ItemDefinition) -> ShopItem:
		var item: ShopItem = ShopItemScene.instantiate()
		item._item_manager = _item_manager
		item.setup(definition)
		add_child_autofree(item)
		return item

	func test_visible_by_default_when_unowned() -> void:
		var item: ShopItem = _make_item(_definition)
		assert_true(item.visible)

	func test_hides_itself_when_its_item_is_taken() -> void:
		var item: ShopItem = _make_item(_definition)
		_item_manager.take(_definition.key)
		assert_false(item.visible)

	func test_stays_visible_when_a_different_item_is_taken() -> void:
		var item: ShopItem = _make_item(_definition)
		var other: ItemDefinition = ItemFactory.create("other_key", &"paddle_speed", &"add", 10.0)
		_item_manager.items.append(other)
		_item_manager.take(other.key)
		assert_true(item.visible)

	func test_starts_hidden_when_definition_is_already_owned() -> void:
		_item_manager.take(_definition.key)
		var item: ShopItem = _make_item(_definition)
		assert_false(item.visible)


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
		assert_gt(_panel.items_row.get_child_count(), 0)

	func test_friendship_label_shows_current_balance() -> void:
		var expected_balance: int = _item_manager.get_friendship_point_balance()
		assert_eq(_panel.friendship_label.text, "Friendship: %d" % expected_balance)
