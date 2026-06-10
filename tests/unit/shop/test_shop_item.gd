extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const ShopDragTuningScript: GDScript = preload("res://scripts/shop/shop_drag_tuning.gd")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")
const WristBrace: ItemDefinition = preload("res://resources/items/wrist_brace.tres")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")


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
		_item_manager.economy.soul_balance = 0
		assert_false(_item.can_be_owned())

	func test_can_be_owned_returns_true_when_affordable_and_unowned() -> void:
		_item_manager.economy.soul_balance = 1000
		assert_true(_item.can_be_owned())

	func test_can_be_owned_returns_false_when_already_owned() -> void:
		_item_manager.economy.soul_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.can_be_owned())

	func test_can_be_owned_returns_false_after_take() -> void:
		_item_manager.economy.soul_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.can_be_owned())

	func test_is_owned_defaults_to_false() -> void:
		assert_false(_item.is_owned())

	func test_is_owned_returns_true_after_take() -> void:
		_item_manager.economy.soul_balance = 1000
		_item_manager.take(_definition.key)
		assert_true(_item.is_owned())

	func test_can_be_dragged_mirrors_can_be_owned_when_not_owned() -> void:
		_item_manager.economy.soul_balance = 1000
		assert_true(_item.can_be_dragged())

	func test_can_be_dragged_returns_false_when_unaffordable_and_not_owned() -> void:
		_item_manager.economy.soul_balance = 0
		assert_false(_item.can_be_dragged())

	func test_can_be_dragged_returns_true_when_owned_even_if_unaffordable() -> void:
		_item_manager.economy.soul_balance = 1000
		_item_manager.take(_definition.key)
		_item_manager.economy.soul_balance = 0
		assert_true(_item.can_be_dragged())

	func test_purchase_hides_case_overlay() -> void:
		# After SH-258 the shop item is a plain Node2D, so the freeze state on a
		_item_manager.economy.soul_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_item.case_overlay.visible)


class TestShopItemArt:
	extends GutTest

	var _item: ShopItem
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager.items.assign([WristBrace])
		_item_manager.economy.soul_balance = 1000
		_item = ShopItemScene.instantiate()
		_item._item_manager = _item_manager
		add_child_autofree(_item)
		_item.configure(_item_manager, WristBrace)

	func test_configure_instantiates_item_art_under_art_holder() -> void:
		assert_eq(_item.art_holder.get_child_count(), 1)

	func test_configure_stores_item_definition() -> void:
		assert_eq(_item.item_definition, WristBrace)


class TestShopItemInputRelease:
	extends GutTest

	var _item: ShopItem
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager.economy.soul_balance = 1000
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


# SH-332 Bug 3: outside-shop release commits via the controller's spawn_purchased_at.
class TestShopItemOutsideShopReleaseRoutesThroughController:
	extends GutTest

	class _StubController:
		extends Node
		var spawn_calls: Array = []
		var spawn_returns: bool = true

		func spawn_purchased_at(
			item_key: String, world_position: Vector2, velocity: Vector2
		) -> bool:
			spawn_calls.append({"key": item_key, "position": world_position, "velocity": velocity})
			return spawn_returns

	var _item: ShopItem
	var _item_manager: Node
	var _controller: _StubController

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager.economy.soul_balance = 1000
		var definition: ItemDefinition = _item_manager.items[0]
		_item = ShopItemScene.instantiate()
		_item._item_manager = _item_manager
		add_child_autofree(_item)
		_item.configure(_item_manager, definition)

		_controller = _StubController.new()
		_controller.add_to_group(&"drag_controller")
		add_child_autofree(_controller)

	func test_outside_shop_release_invokes_spawn_purchased_at() -> void:
		_item.start_drag()
		# Release at a venue-floor point clearly outside the empty shop area (no _shop_area bound = always outside).
		var release_point := Vector2(800, 300)
		var ok: bool = _item.attempt_release(release_point)
		assert_true(ok, "outside-shop release returns true")
		assert_eq(
			_controller.spawn_calls.size(),
			1,
			"controller.spawn_purchased_at fires exactly once per outside-shop release",
		)
		assert_eq(
			_controller.spawn_calls[0]["position"],
			release_point,
			"the release position is forwarded verbatim so the body lands where the player let go",
		)


# SH-332: travel-based gate distinguishes pure click from real drag inside the shop.
class TestShopItemInsideShopDrag:
	extends GutTest

	var _item: ShopItem
	var _item_manager: Node
	var _shop_area: Area2D
	var _press_anchor: Vector2

	func _make_shop_area(rect_size: Vector2) -> Area2D:
		var area := Area2D.new()
		area.global_position = Vector2.ZERO
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect_size
		collision.shape = rectangle
		area.add_child(collision)
		add_child_autofree(area)
		return area

	func _build_item(definition: ItemDefinition) -> ShopItem:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager.items.assign([definition])
		_item_manager.economy.soul_balance = 10000
		var item: ShopItem = ShopItemScene.instantiate()
		item._item_manager = _item_manager
		item.tuning = ShopDragTuningScript.new()
		add_child_autofree(item)
		item.configure(_item_manager, definition)
		_shop_area = _make_shop_area(Vector2(800, 800))
		item.bind_shop_area(_shop_area)
		return item

	func _start_with_press_at(item: ShopItem, anchor: Vector2) -> void:
		item.start_drag()
		# Anchor the press to a known inside-shop point so threshold checks are deterministic.
		item._press_position = anchor
		item._max_travel_seen = 0.0
		_press_anchor = anchor

	func test_pure_click_inside_shop_no_body_no_purchase() -> void:
		_item = _build_item(WristBrace)
		_start_with_press_at(_item, Vector2.ZERO)
		var ok: bool = _item.attempt_release(Vector2.ZERO)
		assert_true(ok)
		assert_true(_item.visible, "pure click restores the slot")
		assert_eq(_item_manager.get_level(WristBrace.key), 0, "pure click never purchases")

	func test_sub_threshold_release_treated_as_click() -> void:
		_item = _build_item(WristBrace)
		_start_with_press_at(_item, Vector2.ZERO)
		# Travel of 1.9px is below the default 2.0px threshold.
		var ok: bool = _item.attempt_release(Vector2(1.9, 0.0))
		assert_true(ok)
		assert_true(_item.visible, "sub-threshold travel keeps the slot visible")
		assert_eq(_item_manager.get_level(WristBrace.key), 0, "sub-threshold never purchases")

	func test_supra_threshold_release_spawns_falling_body_and_hides_slot() -> void:
		_item = _build_item(WristBrace)
		_start_with_press_at(_item, Vector2.ZERO)
		# 2.1px clears the default 2.0px threshold so the inside-shop drag spawns a body.
		var ok: bool = _item.attempt_release(Vector2(2.1, 0.0))
		assert_true(ok)
		assert_false(_item.visible, "the slot stays hidden until the settled-body decision lands")
		assert_eq(_item_manager.get_level(WristBrace.key), 0, "purchase has not committed yet")

	func test_equipment_role_inside_shop_drag_spawns_body() -> void:
		# Regression for the deleted supports_drop gate: equipment items also produce falling bodies.
		_item = _build_item(WristBrace)
		_start_with_press_at(_item, Vector2.ZERO)
		var ok: bool = _item.attempt_release(Vector2(50.0, 0.0))
		assert_true(ok)
		assert_false(
			_item.visible,
			"equipment-role drag inside shop must spawn a body (not snap back like the old gate did)",
		)

	func test_threshold_reads_from_tuning_resource() -> void:
		_item = _build_item(WristBrace)
		# Bump the threshold so a 5px travel falls below it.
		_item.tuning.drag_threshold_px = 10.0
		_start_with_press_at(_item, Vector2.ZERO)
		var ok: bool = _item.attempt_release(Vector2(5.0, 0.0))
		assert_true(ok)
		assert_true(_item.visible, "tuning resource governs the click/drag boundary")

	func test_out_and_back_drag_still_spawns_body() -> void:
		# _max_travel_seen captures peak excursion, so a player who drags out and back to origin still drops a body.
		_item = _build_item(WristBrace)
		_start_with_press_at(_item, Vector2.ZERO)
		_item._max_travel_seen = 50.0
		var ok: bool = _item.attempt_release(Vector2.ZERO)
		assert_true(ok)
		assert_false(
			_item.visible,
			"peak travel above threshold qualifies as a real drag even if release lands at the press point",
		)


# SH-332: notify_body_settled handles the inside-shop / outside-shop decision and the unaffordable-at-settle case.
class TestShopItemNotifyBodySettled:
	extends GutTest

	var _item: ShopItem
	var _item_manager: Node
	var _shop_area: Area2D

	func _make_shop_area(rect_size: Vector2) -> Area2D:
		var area := Area2D.new()
		area.global_position = Vector2.ZERO
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect_size
		collision.shape = rectangle
		area.add_child(collision)
		add_child_autofree(area)
		return area

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager.items.assign([WristBrace])
		_item_manager.economy.soul_balance = 10000
		_item = ShopItemScene.instantiate()
		_item._item_manager = _item_manager
		add_child_autofree(_item)
		_item.configure(_item_manager, WristBrace)
		_shop_area = _make_shop_area(Vector2(200, 200))
		_item.bind_shop_area(_shop_area)
		_item.visible = false

	func _make_body() -> HeldBody:
		var body: HeldBody = HeldBodyScene.instantiate()
		body.item_key = WristBrace.key
		add_child_autofree(body)
		return body

	func test_settle_inside_shop_frees_body_and_restores_slot() -> void:
		var body: HeldBody = _make_body()
		_item.notify_body_settled(body, Vector2(10, 10))
		assert_true(_item.visible, "settle inside shop returns the slot")
		assert_eq(
			_item_manager.get_level(WristBrace.key), 0, "settle inside shop must not purchase"
		)

	func test_settle_outside_shop_commits_purchase() -> void:
		var body: HeldBody = _make_body()
		# 9999, 9999 is well outside the 200x200 shop area centred on origin.
		_item.notify_body_settled(body, Vector2(9999, 9999))
		assert_eq(
			_item_manager.get_level(WristBrace.key), 1, "settle outside shop commits the purchase"
		)
		assert_false(
			_item.visible, "purchased slot stays hidden until the shop refresh removes its node"
		)

	func test_settle_outside_shop_when_unaffordable_frees_body_and_restores_slot() -> void:
		# Drain soul after the gesture started so the player can no longer afford the item.
		_item_manager.economy.soul_balance = 0
		var body: HeldBody = _make_body()
		_item.notify_body_settled(body, Vector2(9999, 9999))
		assert_eq(
			_item_manager.get_level(WristBrace.key), 0, "unaffordable-at-settle does not purchase"
		)
		assert_true(
			_item.visible, "unaffordable settle restores the slot rather than leaking the body"
		)
