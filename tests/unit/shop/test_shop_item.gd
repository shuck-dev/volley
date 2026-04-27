extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")


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
		add_child_autofree(_item)
		_item.configure(_item_manager, _definition)

	func test_can_be_owned_returns_false_without_definition() -> void:
		var bare_item: ShopItem = ShopItemScene.instantiate()
		bare_item._item_manager = _item_manager
		add_child_autofree(bare_item)
		assert_false(bare_item.can_be_owned())

	func test_can_be_owned_returns_false_when_balance_too_low() -> void:
		_item_manager._progression.friendship_point_balance = 0
		assert_false(_item.can_be_owned())

	func test_can_be_owned_returns_true_when_affordable_and_unowned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		assert_true(_item.can_be_owned())

	func test_can_be_owned_returns_false_when_already_owned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.can_be_owned())

	func test_can_be_owned_returns_false_after_take() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.can_be_owned())

	func test_is_owned_defaults_to_false() -> void:
		assert_false(_item.is_owned())

	func test_is_owned_returns_true_after_take() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		assert_true(_item.is_owned())

	func test_can_be_dragged_mirrors_can_be_owned_when_not_owned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		assert_true(_item.can_be_dragged())

	func test_can_be_dragged_returns_false_when_unaffordable_and_not_owned() -> void:
		_item_manager._progression.friendship_point_balance = 0
		assert_false(_item.can_be_dragged())

	func test_can_be_dragged_returns_true_when_owned_even_if_unaffordable() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		_item_manager._progression.friendship_point_balance = 0
		assert_true(_item.can_be_dragged())

	func test_purchase_hides_case_overlay() -> void:
		# After SH-258 the shop item is a plain Node2D, so the freeze state on a
		# RigidBody2D no longer applies. The case overlay still flips off when
		# the player owns the item.
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.case_overlay.visible)


class TestShopItemArt:
	extends GutTest

	const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")

	var _item: ShopItem
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager.items.assign([GripTape])
		_item_manager._progression.friendship_point_balance = 1000
		_item = ShopItemScene.instantiate()
		_item._item_manager = _item_manager
		add_child_autofree(_item)
		_item.configure(_item_manager, GripTape)

	func test_configure_instantiates_item_art_under_art_holder() -> void:
		assert_eq(_item.art_holder.get_child_count(), 1)

	func test_configure_stores_item_definition() -> void:
		assert_eq(_item.item_definition, GripTape)


class TestShopItemInputRelease:
	extends GutTest

	var _item: ShopItem
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager._progression.friendship_point_balance = 1000
		var definition: ItemDefinition = _item_manager.items[0]
		_item = ShopItemScene.instantiate()
		_item._item_manager = _item_manager
		add_child_autofree(_item)
		_item.configure(_item_manager, definition)

	func test_mouse_button_release_event_resolves_active_drag() -> void:
		_item.start_drag()
		assert_true(_item.is_dragging(), "precondition: drag is active")

		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = false
		_item._input(event)

		assert_false(_item.is_dragging(), "mouse-up should resolve the active drag")

	func test_mouse_button_release_event_ignored_when_not_dragging() -> void:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = false
		_item._input(event)

		assert_false(_item.is_dragging(), "no drag started by stray release event")

	func test_non_left_button_release_does_not_end_drag() -> void:
		_item.start_drag()
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_RIGHT
		event.pressed = false
		_item._input(event)

		assert_true(_item.is_dragging(), "right-button release must not end the gesture")
