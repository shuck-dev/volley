extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")

var _drag: ItemDragController


func before_each() -> void:
	BallTestHelpers.use_autoloads(self, [BallTestHelpers.make_ball_item("ball_alpha")])

	_drag = ItemDragControllerScript.new()
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(self)


func after_each() -> void:
	await get_tree().process_frame


func test_grab_live_ball_and_release_over_court_spawns_it_there() -> void:
	var key: String = BallManager.take("ball_alpha")
	BallManager.activate(key)
	assert_not_null(BallTracker.bring_into_play(key, Vector2.ZERO, Vector2(200, 0)))

	assert_true(_drag.grab(key))

	var court_point := Vector2(50, -25)
	assert_true(_drag.attempt_release(court_point))

	var reinstated: Ball = BallTracker.get_ball_for_key(key)
	assert_not_null(reinstated)
	assert_eq(reinstated.global_position, court_point)
