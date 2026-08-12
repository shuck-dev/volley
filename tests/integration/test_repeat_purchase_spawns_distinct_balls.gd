extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const StandardBall: BallDefinition = preload("res://resources/items/standard_ball.tres")

var _manager: Node
var _reconciler: BallReconciler
var _drag: ItemDragController
var _item: ShopItem


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	_manager.items.assign([StandardBall] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	var rack: RackDisplay = BallTestHelpers.make_rack(_manager, self)
	var rack_drop_area: Area2D = BallTestHelpers.make_drop_area(
		Vector2(-1000, 0), Vector2(300, 200), self
	)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, rack, rack_drop_area, _reconciler)
	_drag.kit = BallTestHelpers.make_kit(_manager, self)
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _reconciler, rack_drop_area.position, self)

	_item = ShopItemScene.instantiate()
	_item._ball_manager = _manager
	add_child_autofree(_item)
	_item.configure(_manager, StandardBall)


func after_each() -> void:
	await get_tree().process_frame


func test_second_purchase_released_on_court_spawns_a_second_distinct_ball() -> void:
	_item.start_drag()
	assert_true(_item.attempt_release(Vector2(100, 50)))
	var first_ball: Ball = _reconciler.get_ball_for_key(StandardBall.key)
	assert_not_null(first_ball)

	_item.visible = true
	_item.start_drag()
	assert_true(_item.attempt_release(Vector2(200, 60)))

	assert_eq(_manager.get_owned_count(StandardBall.key), 2)
	assert_true(
		is_instance_valid(first_ball),
		"the first purchased ball should not be replaced or freed by the second purchase",
	)
	assert_eq(
		first_ball.global_position,
		Vector2(100, 50),
		"the second purchase must not move the first ball",
	)

	var balls_on_court: int = 0
	for ball: Ball in _reconciler.get_balls():
		if _manager.is_on_court(ball.ball_key):
			balls_on_court += 1
	assert_eq(balls_on_court, 2, "both purchased balls should be distinct and both on the court")
