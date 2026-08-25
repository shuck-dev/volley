## Verifies the ball_tracker keeps the same Ball instance across grab, release, re-grab, and re-release.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallTrackerScript: GDScript = preload("res://scripts/items/ball_tracker.gd")

var _manager: Node
var _host: Node2D
var _ball_tracker: Node
var _drag: ItemDragController


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	_manager.items.assign([BallTestHelpers.make_ball_item("ball_alpha")] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	_host = Node2D.new()
	_host.name = "BallHost"
	add_child_autofree(_host)

	_ball_tracker = BallTrackerScript.new()
	_ball_tracker.configure(_manager)
	_host.add_child(_ball_tracker)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _ball_tracker)
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _ball_tracker, self)


func after_each() -> void:
	await get_tree().process_frame


func test_regrab_preserves_instance_id() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _ball_tracker.bring_into_play("ball_alpha", Vector2.ZERO, Vector2(200, 0))
	assert_not_null(live, "precondition: an in-play Ball exists")
	var live_id: int = live.get_instance_id()

	assert_true(_drag.grab_live_ball("ball_alpha"))
	assert_true(_drag.attempt_release(Vector2(50, 25)))

	var first_release: Ball = _ball_tracker.get_ball_for_key("ball_alpha")
	assert_eq(first_release.get_instance_id(), live_id)

	assert_true(_drag.grab_live_ball("ball_alpha"))
	assert_eq(_ball_tracker.get_ball_for_key("ball_alpha").play_state, Ball.PlayState.OUT_HELD)

	assert_true(_drag.attempt_release(Vector2(50, 25)))

	assert_eq(_ball_tracker.get_ball_for_key("ball_alpha").get_instance_id(), live_id)
