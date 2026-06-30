extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")
const WristBrace: ItemDefinition = preload("res://resources/items/wrist_brace.tres")


## Player cannot drag or buy items they cannot afford.
func test_unaffordable_and_unowned_cannot_be_dragged() -> void:
	var manager := ItemFactory.create_manager(self)
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, manager.items[0])
	manager.economy.soul_balance = 0
	assert_false(item.can_be_dragged())


## Player can drag affordable, unowned items.
func test_affordable_unowned_can_be_dragged() -> void:
	var manager := ItemFactory.create_manager(self)
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, manager.items[0])
	manager.economy.soul_balance = 1000
	assert_true(item.can_be_dragged())


## Player can drag owned items even without balance.
func test_owned_can_be_dragged_regardless_of_balance() -> void:
	var manager := ItemFactory.create_manager(self)
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, manager.items[0])
	manager.economy.soul_balance = 1000
	manager.take(manager.items[0].key)
	manager.economy.soul_balance = 0
	assert_true(item.can_be_dragged())


## Releasing inside shop without movement restores the slot without purchase.
func test_release_without_movement_restores_slot() -> void:
	var manager := ItemFactory.create_manager(self)
	manager.items.assign([WristBrace as ItemDefinition])
	manager.economy.soul_balance = 10000
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, WristBrace)

	var area := Area2D.new()
	area.global_position = Vector2.ZERO
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(800, 800)
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	item.bind_shop_area(area)

	item.start_drag()
	item._press_position = Vector2.ZERO
	item._max_travel_seen = 0.0

	var ok: bool = item.attempt_release(Vector2.ZERO)
	assert_true(ok)
	assert_true(item.visible, "slot should be visible after pure click")
	assert_eq(manager.get_level(WristBrace.key), 0, "no purchase on pure click")


## Releasing outside shop area commits the purchase.
func test_release_outside_shop_commits_purchase() -> void:
	var manager := ItemFactory.create_manager(self)
	manager.items.assign([WristBrace as ItemDefinition])
	manager.economy.soul_balance = 10000
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, WristBrace)

	item.start_drag()
	var ok: bool = item.attempt_release(Vector2(800, 300))
	assert_true(ok)
	assert_false(item.visible, "slot hidden after purchase")
	assert_eq(manager.get_level(WristBrace.key), 1, "purchase committed")


## Body settling outside shop commits the purchase.
func test_settle_outside_shop_commits_purchase() -> void:
	var manager := ItemFactory.create_manager(self)
	manager.items.assign([WristBrace as ItemDefinition])
	manager.economy.soul_balance = 10000
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, WristBrace)

	var area := Area2D.new()
	area.global_position = Vector2.ZERO
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(200, 200)
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	item.bind_shop_area(area)
	item.visible = false

	var body := HeldBodyScene.instantiate()
	body.item_key = WristBrace.key
	add_child_autofree(body)
	item.notify_body_settled(body, Vector2(9999, 9999))
	assert_eq(manager.get_level(WristBrace.key), 1, "purchase committed on outside settle")
	assert_false(item.visible, "slot hidden after purchase")


## Body settling inside shop restores the slot without purchase.
func test_settle_inside_shop_restores_slot() -> void:
	var manager := ItemFactory.create_manager(self)
	manager.items.assign([WristBrace as ItemDefinition])
	manager.economy.soul_balance = 10000
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, WristBrace)

	var area := Area2D.new()
	area.global_position = Vector2.ZERO
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(200, 200)
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	item.bind_shop_area(area)
	item.visible = false

	var body := HeldBodyScene.instantiate()
	body.item_key = WristBrace.key
	add_child_autofree(body)
	item.notify_body_settled(body, Vector2(10, 10))
	assert_true(item.visible, "slot restored after inside settle")
	assert_eq(manager.get_level(WristBrace.key), 0, "no purchase on inside settle")
