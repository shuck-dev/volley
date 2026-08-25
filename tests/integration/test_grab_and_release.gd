extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallTrackerScript: GDScript = preload("res://scripts/items/ball_tracker.gd")

var _manager: Node
var _ball_tracker: Node
var _drag: ItemDragController


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	var ball_alpha: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	_manager.items.assign([ball_alpha] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	_ball_tracker = BallTrackerScript.new()
	_ball_tracker.configure(_manager)
	add_child_autofree(_ball_tracker)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _ball_tracker)
	_drag.kit = BallTestHelpers.make_kit(_manager, self)
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _ball_tracker, self)


func after_each() -> void:
	await get_tree().process_frame


func test_grab_live_ball_and_release_over_court_resumes_rally() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _ball_tracker.bring_into_play("ball_alpha", Vector2.ZERO, Vector2(200, 0))
	assert_not_null(live)

	assert_true(_drag.grab_live_ball("ball_alpha"))
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD)

	var court_point := Vector2(50, -25)
	assert_true(_drag.attempt_release(court_point))

	var reinstated: Ball = _ball_tracker.get_ball_for_key("ball_alpha")
	assert_eq(reinstated, live)
	assert_eq(reinstated.global_position, court_point)
