extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: ItemDragController


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpers.make_ball_item("ball_alpha")
	_manager.items.assign([ball_alpha] as Array[ItemDefinition])
	_manager.economy.soul_balance = 10000

	_rack = ItemTestHelpers.make_rack(_manager, self)
	_drop_target = ItemTestHelpers.make_drop_area(Vector2(-1000, 0), Vector2(300, 200), self)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


func after_each() -> void:
	await get_tree().process_frame


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
		if child is Ball:
			result.append(child)
	return result


func test_grab_from_rack_and_release_over_court_launches_ball() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": Vector2(0, 0)})
	_drag._cursor_samples.append({"time": 0.04, "position": Vector2(200, 0)})

	var court_point := Vector2(100, 50)
	assert_true(_drag.attempt_release(court_point))
	assert_false(_drag.is_dragging())

	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball)
	assert_eq(ball.global_position, court_point)
	assert_gt(ball.linear_velocity.length(), 0.0)


func test_click_on_rack_without_movement_cancels_back_to_rack() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	var released: bool = _drag.attempt_release(_drop_target.global_position)
	assert_true(released)
	assert_false(_drag.is_dragging())
	assert_false(_manager.is_on_court("ball_alpha"))
	assert_eq(_permanent_balls().size(), 0)


func test_grab_live_ball_and_release_over_court_resumes_rally() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live)

	assert_true(_drag.grab_live_ball("ball_alpha", false))
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD)

	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": Vector2(0, 0)})
	_drag._cursor_samples.append({"time": 0.04, "position": Vector2(40, 0)})

	var court_point := Vector2(50, -25)
	assert_true(_drag.attempt_release(court_point))

	var reinstated: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(reinstated, live)
	assert_eq(reinstated.global_position, court_point)


func test_grab_equipped_from_character_and_release_on_rack_unequips() -> void:
	var equipment: ItemDefinition = ItemTestHelpers.make_equipment_item("gear")
	var typed_items: Array[ItemDefinition] = [equipment]
	for existing in _manager.items:
		typed_items.append(existing)
	_manager.items.assign(typed_items)
	_manager.take("gear")
	_manager.state.item_placements["gear"] = Placement.EQUIPPED

	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	timeout._state = TimeoutController.State.AT_EQUIP_POSE
	_drag.timeout_controller = timeout
	_drag.gear_rack = _rack
	_drag.gear_rack_drop_target = _drop_target
	_drag.set_character_drop_target(
		ItemTestHelpers.make_drop_area(Vector2(0, 0), Vector2(40, 80), self)
	)

	assert_true(_drag.grab_equipped_from_character("gear", Vector2.ZERO))
	assert_eq(_manager.get_placement("gear"), Placement.STORED)

	_drag._track_cursor_motion(_drop_target.global_position)
	_drag._gesture_below_threshold = false
	assert_true(_drag.attempt_release(_drop_target.global_position))
	assert_false(_drag.is_dragging())
