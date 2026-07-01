extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")
const StandardBall: ItemDefinition = preload("res://resources/items/standard_ball.tres")


func test_unaffordable_unowned_cannot_be_dragged() -> void:
	var context: Dictionary = _make_item(null)
	context["manager"].economy.soul_balance = 0
	assert_false(context["item"].can_be_dragged())


func test_affordable_unowned_can_be_dragged() -> void:
	var context: Dictionary = _make_item(StandardBall)
	assert_true(context["item"].can_be_dragged())


func test_owned_can_be_dragged_regardless_of_balance() -> void:
	var context: Dictionary = _make_item(StandardBall)
	context["manager"].take(StandardBall.key)
	context["manager"].economy.soul_balance = 0
	assert_true(context["item"].can_be_dragged())


func test_release_outside_shop_commits_purchase() -> void:
	var context: Dictionary = _make_item(StandardBall)
	var item: ShopItem = context["item"]

	item.start_drag()
	var ok: bool = item.attempt_release(Vector2(800, 300))
	assert_true(ok)
	assert_false(item.visible, "slot hidden after purchase")
	assert_eq(context["manager"].get_level(StandardBall.key), 1, "purchase committed")


func test_inside_shop_drag_spawns_body_without_purchase() -> void:
	var context: Dictionary = _make_item(StandardBall)
	var item: ShopItem = context["item"]
	item.bind_shop_area(_make_shop_area(Vector2(800, 800)))

	item.start_drag()
	item._press_position = Vector2.ZERO
	item._max_travel_seen = 50.0
	var ok: bool = item.attempt_release(Vector2.ZERO)
	assert_true(ok)
	assert_false(item.visible, "slot hidden after inside-shop drag")
	assert_eq(context["manager"].get_level(StandardBall.key), 0, "purchase deferred to settle")


func test_settle_outside_shop_commits_purchase() -> void:
	var context: Dictionary = _make_item(StandardBall)
	var item: ShopItem = context["item"]
	item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	item.visible = false
	item.notify_body_settled(_make_held_body(StandardBall.key), Vector2(9999, 9999))

	assert_eq(
		context["manager"].get_level(StandardBall.key), 1, "purchase committed on outside settle"
	)
	assert_false(item.visible, "slot hidden after purchase")


func test_settle_outside_shop_when_unaffordable_restores_slot() -> void:
	var context: Dictionary = _make_item(StandardBall)
	var item: ShopItem = context["item"]
	item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	item.visible = false
	context["manager"].economy.soul_balance = 0
	item.notify_body_settled(_make_held_body(StandardBall.key), Vector2(9999, 9999))

	assert_true(item.visible, "slot restored when unaffordable")
	assert_eq(context["manager"].get_level(StandardBall.key), 0, "no purchase when broke")


func test_settle_inside_shop_restores_slot() -> void:
	var context: Dictionary = _make_item(StandardBall)
	var item: ShopItem = context["item"]
	item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	item.visible = false
	item.notify_body_settled(_make_held_body(StandardBall.key), Vector2(10, 10))

	assert_true(item.visible, "slot restored after inside settle")
	assert_eq(context["manager"].get_level(StandardBall.key), 0, "no purchase on inside settle")


func _make_item(definition: ItemDefinition) -> Dictionary:
	var manager := ItemFactory.create_manager(self)
	if definition != null:
		manager.items.assign([definition])
	manager.economy.soul_balance = 10000
	var item := ShopItemScene.instantiate()
	item._item_manager = manager
	add_child_autofree(item)
	item.configure(manager, definition if definition != null else manager.items[0])
	return {"manager": manager, "item": item}


func _make_shop_area(size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = Vector2.ZERO
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func _make_held_body(key: String) -> HeldBody:
	var body := HeldBodyScene.instantiate()
	body.item_key = key
	add_child_autofree(body)
	return body
