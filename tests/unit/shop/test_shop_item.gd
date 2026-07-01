extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")
const StandardBall: ItemDefinition = preload("res://resources/items/standard_ball.tres")

var _manager: Node
var _item: ShopItem


func test_unaffordable_unowned_cannot_be_dragged() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 0
	assert_false(_item.can_be_dragged())


func test_affordable_unowned_can_be_dragged() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	assert_true(_item.can_be_dragged())


func test_owned_can_be_dragged_regardless_of_balance() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_manager.take(StandardBall.key)
	_manager.economy.soul_balance = 0
	assert_true(_item.can_be_dragged())


func test_release_outside_shop_commits_purchase() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.start_drag()
	var ok: bool = _item.attempt_release(Vector2(800, 300))
	assert_true(ok)
	assert_false(_item.visible, "slot hidden after purchase")
	assert_eq(_manager.get_level(StandardBall.key), 1, "purchase committed")


func test_inside_shop_drag_spawns_body_without_purchase() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.bind_shop_area(_make_shop_area(Vector2(800, 800)))
	_item.start_drag()
	_item._press_position = Vector2.ZERO
	_item._max_travel_seen = 50.0
	var ok: bool = _item.attempt_release(Vector2.ZERO)
	assert_true(ok)
	assert_false(_item.visible, "slot hidden after inside-shop drag")
	assert_eq(_manager.get_level(StandardBall.key), 0, "purchase deferred to settle")


func test_settle_outside_shop_commits_purchase() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	_item.visible = false
	_item.notify_body_settled(_make_held_body(StandardBall.key), Vector2(9999, 9999))
	assert_eq(_manager.get_level(StandardBall.key), 1, "purchase committed on outside settle")
	assert_false(_item.visible, "slot hidden after purchase")


func test_settle_outside_shop_when_unaffordable_restores_slot() -> void:
	_setup_item(StandardBall)
	_item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	_item.visible = false
	_manager.economy.soul_balance = 0
	_item.notify_body_settled(_make_held_body(StandardBall.key), Vector2(9999, 9999))
	assert_true(_item.visible, "slot restored when unaffordable")
	assert_eq(_manager.get_level(StandardBall.key), 0, "no purchase when broke")


func test_settle_inside_shop_restores_slot() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	_item.visible = false
	_item.notify_body_settled(_make_held_body(StandardBall.key), Vector2(10, 10))
	assert_true(_item.visible, "slot restored after inside settle")
	assert_eq(_manager.get_level(StandardBall.key), 0, "no purchase on inside settle")


func _setup_item(definition: ItemDefinition) -> void:
	_manager = ItemFactory.create_manager(self)
	_manager.items.assign([definition])
	_item = ShopItemScene.instantiate()
	_item._item_manager = _manager
	add_child_autofree(_item)
	_item.configure(_manager, definition)


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
