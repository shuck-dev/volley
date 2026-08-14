extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: Node
var _drag: ItemDragController


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	var ball_alpha: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	_manager.items.assign([ball_alpha] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	_rack = BallTestHelpers.make_rack(_manager, self)
	_drop_target = BallTestHelpers.make_drop_area(Vector2(-1000, 0), Vector2(300, 200), self)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.kit = BallTestHelpers.make_kit(_manager, self)
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _reconciler, _drop_target.position, self)


func after_each() -> void:
	await get_tree().process_frame


func test_grab_live_ball_and_release_over_court_resumes_rally() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live)

	assert_true(_drag.grab_live_ball("ball_alpha"))
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD)

	var court_point := Vector2(50, -25)
	assert_true(_drag.attempt_release(court_point))

	var reinstated: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(reinstated, live)
	assert_eq(reinstated.global_position, court_point)
