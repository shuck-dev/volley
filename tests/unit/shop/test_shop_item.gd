extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const StandardBall: ItemDefinition = preload("res://resources/items/standard_ball.tres")

var _manager: Node
var _reconciler: BallReconciler
var _drag: ItemDragController
var _item: ShopItem


func test_unaffordable_unowned_cannot_be_dragged() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 0
	assert_false(_item.can_be_owned())


func test_affordable_unowned_can_be_dragged() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	assert_true(_item.can_be_owned())


func test_owned_item_can_be_dragged() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_manager.take(StandardBall.key)
	assert_true(_item.can_be_owned())


func test_owned_item_cannot_be_dragged_when_broke() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_manager.take(StandardBall.key)
	_manager.economy.soul_balance = 0
	assert_false(_item.can_be_owned())


func test_release_outside_shop_commits_purchase() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.start_drag()
	var ok: bool = _item.attempt_release(Vector2(100, 50))
	assert_true(ok)
	assert_false(_item.visible, "slot hidden after purchase")
	assert_eq(_manager.economy.soul_balance, 9990, "purchase committed")


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

	var released: bool = _item.attempt_release(Vector2(100, 50))

	assert_true(released, "an unaffordable drop resolves the gesture instead of hanging")
	assert_true(_item.visible, "slot restored when the drop is unaffordable")
	assert_eq(_manager.get_level(StandardBall.key), 0, "no purchase when unaffordable")


func test_owned_ball_can_be_upgraded_from_shop() -> void:
	_setup_item(StandardBall)
	_manager.economy.soul_balance = 10000
	_item.start_drag()
	_item.attempt_release(Vector2(100, 50))
	assert_eq(_manager.get_level(StandardBall.key), 1, "first purchase sets level 1")

	_item.visible = true
	_item.start_drag()
	_item.attempt_release(Vector2(100, 50))
	assert_eq(_manager.get_level(StandardBall.key), 2, "re-purchase upgrades to level 2")
	assert_false(_item.visible, "slot hidden after re-purchase")


func _setup_item(definition: ItemDefinition) -> void:
	_manager = ItemFactory.create_manager(self)
	_manager.items.assign([definition])

	var rack: RackDisplay = ItemTestHelpers.make_rack(_manager, self)
	var rack_drop_area: Area2D = ItemTestHelpers.make_drop_area(
		Vector2(-1000, 0), Vector2(300, 200), self
	)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, rack, rack_drop_area, _reconciler)
	add_child_autofree(_drag)

	ItemTestHelpers.make_drop_targets(_manager, _reconciler, rack_drop_area.position, self)

	_item = ShopItemScene.instantiate()
	_item._item_manager = _manager
	add_child_autofree(_item)
	_item.configure(_manager, definition)
