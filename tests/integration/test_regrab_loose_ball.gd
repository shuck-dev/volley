## A grab deconstructs the ball, so each release spawns a fresh instance for the same key.
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


func test_regrab_replaces_the_instance() -> void:
	var key: String = BallManager.take("ball_alpha")
	BallManager.activate(key)
	var live: Ball = BallTracker.bring_into_play(key, Vector2.ZERO, Vector2(200, 0))
	assert_not_null(live, "precondition: an in-play Ball exists")
	var live_id: int = live.get_instance_id()

	assert_true(_drag.grab(key))
	assert_true(_drag.attempt_release(Vector2(50, 25)))

	var first_release: Ball = BallTracker.get_ball_for_key(key)
	assert_not_null(first_release)
	assert_ne(first_release.get_instance_id(), live_id)


func test_regrab_leaves_one_ball_for_the_key() -> void:
	var key: String = BallManager.take("ball_alpha")
	BallManager.activate(key)
	BallTracker.bring_into_play(key, Vector2.ZERO, Vector2(200, 0))

	assert_true(_drag.grab(key))
	assert_true(_drag.attempt_release(Vector2(50, 25)))
	assert_true(_drag.grab(key))
	assert_true(_drag.attempt_release(Vector2(50, 25)))

	assert_not_null(BallTracker.get_ball_for_key(key))
