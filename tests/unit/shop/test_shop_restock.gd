extends GutTest

const ShopScript: GDScript = preload("res://scripts/shop/shop.gd")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const ConfigScript: GDScript = preload("res://scripts/shop/shop_config.gd")


class TestShopRefresh:
	extends GutTest

	var _manager: Node
	var _shop: Node
	var _items_anchor: Node2D
	var _ball_a: ItemDefinition
	var _ball_b: ItemDefinition
	var _count_label: Label
	var _cost_label: Label
	var _button: Button

	func before_each() -> void:
		var valid_art: PackedScene = _make_valid_art()

		_ball_a = ItemTestHelpers.make_ball_item("test_ball_a")
		_ball_a.base_cost = 100
		_ball_a.art = valid_art
		_ball_b = ItemTestHelpers.make_ball_item("test_ball_b")
		_ball_b.base_cost = 50
		_ball_b.art = valid_art

		_manager = ItemFactory.create_manager(self)
		_manager.items.assign([_ball_a, _ball_b])
		_manager.economy.soul_balance = 1000

		_items_anchor = Node2D.new()
		_items_anchor.name = "ItemsAnchor"
		add_child_autofree(_items_anchor)

		_count_label = Label.new()
		add_child_autofree(_count_label)
		_cost_label = Label.new()
		add_child_autofree(_cost_label)
		_button = Button.new()
		add_child_autofree(_button)

		_shop = ShopScript.new()
		_shop._item_manager = _manager
		_shop.items_anchor = _items_anchor
		_shop.refresh_count_label = _count_label
		_shop.refresh_cost_label = _cost_label
		_shop.refresh_button = _button
		var config: ShopConfig = ConfigScript.new()
		config.display_slots = 2
		config.item_spacing = 80.0
		_shop.config = config
		add_child_autofree(_shop)
		_shop.refresh_count = 0
		_populate_items()

	func _make_valid_art() -> PackedScene:
		var scene := PackedScene.new()
		var template := ItemArt.new()
		scene.pack(template)
		template.free()
		return scene

	func _populate_items() -> void:
		for child in _items_anchor.get_children():
			if child is ShopItem:
				child.queue_free()
		await get_tree().process_frame

		var item_a: ShopItem = ShopItemScene.instantiate()
		item_a._item_manager = _manager
		_items_anchor.add_child(item_a)
		item_a.configure(_manager, _ball_a)

		var item_b: ShopItem = ShopItemScene.instantiate()
		item_b._item_manager = _manager
		_items_anchor.add_child(item_b)
		item_b.configure(_manager, _ball_b)

	func test_first_refresh_is_free() -> void:
		_shop.refresh_count = 0
		var balance_before: int = _manager.get_soul_balance()
		_shop._on_refresh_pressed()
		assert_eq(_manager.get_soul_balance(), balance_before, "first refresh free")

	func test_refresh_increments_count() -> void:
		_shop.refresh_count = 0
		_shop._on_refresh_pressed()
		assert_eq(_shop.refresh_count, 1, "count increments after first refresh")

	func test_rotation_cost_sums_displayed_items() -> void:
		assert_eq(_shop._rotation_cost(), 150, "rotation cost is sum of displayed item costs")

	func test_rotation_cost_scales_with_item_level() -> void:
		_manager.state.item_levels["test_ball_a"] = 1
		_populate_items()
		assert_eq(_shop._rotation_cost(), 250, "item cost doubles per level for ball role")

	func test_second_refresh_costs_rotation_cost() -> void:
		_shop.refresh_count = 1
		_shop.refresh_count_label = null
		_shop.refresh_cost_label = null
		_shop.refresh_button = null
		var balance_before: int = _manager.get_soul_balance()
		_shop._on_refresh_pressed()
		assert_true(_manager.get_soul_balance() < balance_before, "second refresh deducts soul")

	func test_refresh_blocks_when_broke() -> void:
		_shop.refresh_count = 1
		_manager.economy.soul_balance = 0
		var balance_before: int = _manager.get_soul_balance()
		_shop._on_refresh_pressed()
		assert_eq(_shop.refresh_count, 1, "count unchanged when refresh blocked")
		assert_eq(
			_manager.get_soul_balance(), balance_before, "no soul deducted when refresh blocked"
		)

	func test_refresh_after_buying_increases_cost() -> void:
		_manager.state.item_levels["test_ball_a"] = 1
		_populate_items()
		_shop.refresh_count = 1
		var cost: int = _shop._rotation_cost() * _shop.refresh_count
		assert_eq(cost, 250, "cost reflects higher item level after purchase")

	func test_multiple_refreshes_increase_cost_linearly() -> void:
		_shop.refresh_count = 3
		var cost: int = _shop._rotation_cost() * _shop.refresh_count
		assert_eq(cost, 450, "cost equals rotation_cost by refresh_count")
