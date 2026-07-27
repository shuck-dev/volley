extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
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


func test_owned_item_can_be_dragged() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_manager.take(StandardBall.key)
	assert_true(_item.can_be_dragged())


func test_owned_item_can_be_dragged_when_broke() -> void:
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
	assert_eq(_manager.economy.soul_balance, 9990, "purchase committed")


func test_settle_outside_shop_commits_purchase() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	_item.visible = false
	_item.notify_body_settled(_make_ball(StandardBall.key), Vector2(9999, 9999))
	assert_eq(_manager.economy.soul_balance, 9990, "purchase committed on outside settle")
	assert_false(_item.visible, "slot hidden after purchase")


func test_settle_outside_shop_when_unaffordable_restores_slot() -> void:
	_setup_item(StandardBall)
	_item.bind_shop_area(_make_shop_area(Vector2(200, 200)))
	_item.visible = false
	_manager.economy.soul_balance = 0
	_item.notify_body_settled(_make_ball(StandardBall.key), Vector2(9999, 9999))
	assert_true(_item.visible, "slot restored when unaffordable")
	assert_eq(_manager.get_level(StandardBall.key), 0, "no purchase when broke")


func test_release_where_no_target_accepts_keeps_the_item_held() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.start_drag()

	assert_false(
		_item.attempt_release(Vector2(99999, 99999)),
		"a release past every drop target should not commit",
	)
	assert_eq(_manager.economy.soul_balance, 10000, "a refused drop charges nothing")
	assert_eq(_manager.get_level(StandardBall.key), 0, "a refused drop grants no item")


func test_unaffordable_release_outside_shop_cancels_the_drag() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.start_drag()
	_manager.economy.soul_balance = 0

	var released: bool = _item.attempt_release(Vector2(800, 300))

	assert_true(released, "an unaffordable drop resolves the gesture instead of hanging")
	assert_true(_item.visible, "slot restored when the drop is unaffordable")
	assert_eq(_manager.get_level(StandardBall.key), 0, "no purchase when unaffordable")


func test_owned_ball_can_be_upgraded_from_shop() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.start_drag()
	_item.attempt_release(Vector2(800, 300))
	assert_eq(_manager.get_level(StandardBall.key), 1, "first purchase sets level 1")

	_item.visible = true
	_item.start_drag()
	_item.attempt_release(Vector2(800, 300))
	assert_eq(_manager.get_level(StandardBall.key), 2, "re-purchase upgrades to level 2")
	assert_false(_item.visible, "slot hidden after re-purchase")


func _setup_item(definition: ItemDefinition) -> void:
	_manager = ItemFactory.create_manager(self)
	_manager.items.assign([definition])
	_item = ShopItemScene.instantiate()
	_item._item_manager = _manager
	add_child_autofree(_item)
	_item.configure(_manager, definition)
	_make_venue_target()


## A release only commits where a target accepts, so a purchase test needs somewhere to drop into.
func _make_venue_target() -> VenueDropTarget:
	var target := VenueDropTarget.new()
	target.item_manager = _manager
	target.priority = ItemTestHelpers.VENUE_PRIORITY
	target.add_child(ItemTestHelpers.attach_rect_shape(ItemTestHelpers.VENUE_SIZE))
	add_child_autofree(target)
	return target


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


func _make_ball(key: String) -> Ball:
	var ball: Ball = load("res://scripts/entities/ball/ball.gd").new()
	ball.item_key = key
	add_child_autofree(ball)
	return ball
