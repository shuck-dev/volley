extends GutTest

const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallTrackerScript: GDScript = preload("res://scripts/items/ball_tracker.gd")
const StandardBall: BallDefinition = preload("res://resources/items/standard_ball.tres")

var _manager: Node
var _ball_tracker: Node
var _drag: ItemDragController
var _item: ShopItem


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	_manager.items.assign([StandardBall] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	_ball_tracker = BallTrackerScript.new()
	_ball_tracker.configure(_manager)
	add_child_autofree(_ball_tracker)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _ball_tracker)
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _ball_tracker, self)

	_item = ShopItemScene.instantiate()
	_item._ball_manager = _manager
	add_child_autofree(_item)
	_item.configure(_manager, StandardBall)


func after_each() -> void:
	await get_tree().process_frame


func test_second_purchase_released_on_court_spawns_a_second_distinct_ball() -> void:
	_item.accept_payment()
	assert_true(_item.attempt_release(Vector2(100, 50)))
	var first_balls: Array[Ball] = _ball_tracker.get_balls()
	assert_eq(first_balls.size(), 1)
	var first_ball: Ball = first_balls[0]

	_item.visible = true
	_item.accept_payment()
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
	for ball: Ball in _ball_tracker.get_balls():
		if _manager.is_on_court(ball.ball_key):
			balls_on_court += 1
	assert_eq(balls_on_court, 2, "both purchased balls should be distinct and both on the court")
