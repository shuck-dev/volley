extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController


func _make_rack(manager: Node) -> RackDisplay:
	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = &"ball"
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)
	for index in 4:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	rack.slot_container = slot_container
	rack.configure(manager)
	add_child_autofree(rack)
	return rack


func _make_drop_target(position: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _host.get_children():
		if child is Ball:
			result.append(child)
	return result


func _loose_bodies_under_host() -> Array:
	var result: Array = []
	for child in _host.get_children():
		if child is HeldBody:
			result.append(child)
	return result


func test_grab_from_rack_spawns_held_body_without_activating_item() -> void:
	_manager.take("ball_alpha")
	assert_false(_manager.is_on_court("ball_alpha"), "precondition: item is on the rack")

	var ok: bool = _drag.grab_from_rack("ball_alpha")
	assert_true(ok)
	assert_true(_drag.is_dragging(), "drag controller should be mid-gesture after rack pickup")
	assert_eq(_drag.get_held_key(), "ball_alpha")
	assert_false(
		_manager.is_on_court("ball_alpha"),
		"rack pickup is press-hold-release; activation only fires at release over court",
	)


func test_click_on_rack_without_movement_does_not_introduce_ball() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	# Release over the rack drop target with zero cursor movement.
	var rack_position: Vector2 = _drop_target.global_position
	var released: bool = _drag.attempt_release(rack_position)

	assert_true(released)
	assert_false(_drag.is_dragging(), "held body cleared on release")
	assert_false(
		_manager.is_on_court("ball_alpha"),
		"no movement, no court release: the item must not be activated",
	)
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"a click-without-movement must not spawn a live ball",
	)
	assert_eq(_permanent_balls().size(), 0, "no permanent Ball instance should land on the court")


func test_rack_pickup_fails_when_item_unowned() -> void:
	assert_false(_drag.grab_from_rack("ball_alpha"), "cannot pick up an unowned item")
	assert_false(_drag.is_dragging())


func test_release_over_court_instates_a_ball_at_cursor_with_gesture_velocity() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	# Feed a multi-sample gesture moving right across the 80 ms window.
	var start_position := Vector2(0, 0)
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": start_position})
	_drag._cursor_samples.append({"time": 0.04, "position": Vector2(200, 0)})

	var court_point := Vector2(100, 50)
	var released: bool = _drag.attempt_release(court_point)
	assert_true(released, "release over court should resolve")
	assert_false(_drag.is_dragging())

	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "reconciler should own the live ball after a court release")
	assert_eq(ball.global_position, court_point)
	assert_ne(
		ball.linear_velocity, Vector2.ZERO, "gesture-derived velocity should drive the ball launch"
	)
	assert_gt(
		ball.linear_velocity.x, 0.0, "rightward gesture should produce rightward launch velocity"
	)


func test_release_without_gesture_uses_default_launch_velocity() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	# Single sample means no motion - gesture path falls back to the default.
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": Vector2.ZERO})

	var released: bool = _drag.attempt_release(Vector2(100, 50))
	assert_true(released)

	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball)
	var expected: Vector2 = _manager.get_default_ball_launch_velocity()
	assert_eq(ball.linear_velocity, expected, "fallback path should match ItemManager default")


func test_release_far_outside_court_falls_loose_inside_venue() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame
	var off_world := Vector2(99999, 99999)

	var released: bool = _drag.attempt_release(off_world)

	assert_true(released, "venue-clamped release resolves as a loose drop")
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"loose release does not bring the item into play",
	)
	assert_false(_manager.is_on_court("ball_alpha"), "loose release does not flip placement state")
	var loose_bodies: Array = _loose_bodies_under_host()
	assert_eq(loose_bodies.size(), 1, "exactly one loose body lands in the venue")
	var body: HeldBody = loose_bodies[0]
	assert_false(body.freeze, "loose body unfreezes so gravity integrates")
	assert_gt(body.gravity_scale, 0.0, "loose body has gravity active")


func test_release_over_rack_returns_a_court_ball_to_the_rack() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	assert_true(_manager.is_on_court("ball_alpha"), "precondition: item is on court")

	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame
	var over_rack := _drop_target.global_position

	var released: bool = _drag.attempt_release(over_rack)

	assert_true(released)
	assert_false(_drag.is_dragging(), "held body destroyed on rack release")
	assert_false(
		_manager.is_on_court("ball_alpha"),
		"release onto rack should deactivate a permanent ball item",
	)


func test_mid_rally_grab_suspends_live_ball_and_takes_over_cursor() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live, "precondition: live ball exists")

	var ok: bool = _drag.grab_live_ball("ball_alpha", false)
	assert_true(ok)
	assert_true(_drag.is_dragging())
	await get_tree().process_frame
	assert_false(is_instance_valid(live), "live ball should be freed on mid-rally grab")
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"reconciler should release its tracked live ball during the hold",
	)


func test_mid_rally_grab_then_release_over_court_reinstates_a_ball() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame

	var court_point := Vector2(50, -25)
	var released: bool = _drag.attempt_release(court_point)

	assert_true(released)
	var reinstated: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(reinstated, "court release should reinstate a Ball via the reconciler")
	assert_eq(reinstated.global_position, court_point)


func test_temporary_ball_release_over_court_does_not_spawn_through_reconciler() -> void:
	_drag.grab_live_ball("ball_alpha", true)
	assert_true(_drag.is_dragging(), "precondition: held body exists for the temporary drag")
	var body_before: HeldBody = _drag.get_held_body()
	var court_point := Vector2(0, 0)

	var released: bool = _drag.attempt_release(court_point)

	assert_true(released)
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"temporary balls are outside the reconciler's placement-driven set",
	)
	assert_false(_drag.is_dragging(), "temporary release clears the drag state")
	await get_tree().process_frame
	assert_false(is_instance_valid(body_before), "held body should be freed on release")
	assert_eq(
		_permanent_balls().size(), 0, "temporary release should not leave a permanent Ball behind"
	)


func test_release_inside_venue_outside_court_drops_loose() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	# Inside venue_bounds (-2000..2000) but outside court_bounds (-600..600 on x).
	var in_venue_out_of_court := Vector2(1500, 50)
	var released: bool = _drag.attempt_release(in_venue_out_of_court)
	assert_true(released, "release inside venue always resolves, never a no-op")

	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"loose release does not bring the item into play",
	)
	assert_false(_manager.is_on_court("ball_alpha"))
	var loose_bodies: Array = _loose_bodies_under_host()
	assert_eq(loose_bodies.size(), 1, "loose body lands at the release position")
	assert_eq(loose_bodies[0].global_position, in_venue_out_of_court)


func test_mouse_button_release_event_triggers_release() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	# Release position must clear the movement threshold so the controller treats it as a real drag.
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = Vector2(100, 50)
	_drag._input(event)

	assert_false(_drag.is_dragging(), "mouse-up should resolve the active drag")
	assert_not_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"mouse-up over the default court region should spawn the ball",
	)


func test_process_follow_clamps_held_body_to_venue_bounds() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var body: HeldBody = _drag.get_held_body()
	assert_not_null(body, "precondition: held body exists")

	var clamped: Vector2 = _drag._clamp_to_venue(Vector2(99999, -99999))
	assert_eq(clamped, Vector2(2000, -1200), "clamp pulls to the venue rect corner")


func test_clamp_to_venue_is_identity_when_bounds_unset() -> void:
	var unbounded: BallDragController = BallDragControllerScript.new()
	add_child_autofree(unbounded)
	var point := Vector2(12345, -67890)
	assert_eq(unbounded._clamp_to_venue(point), point, "zero-size venue leaves positions untouched")


func test_grab_and_release_preserves_live_ball_speed_through_to_reinstated_ball() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live, "precondition: live ball exists")
	live.speed = 600.0

	var grabbed: bool = _drag.grab_live_ball("ball_alpha", false)
	assert_true(grabbed)
	await get_tree().process_frame
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": Vector2(0, 0)})
	_drag._cursor_samples.append({"time": 0.04, "position": Vector2(40, 0)})

	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = Vector2(120, 30)
	_drag._input(release_event)

	var reinstated: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(reinstated, "release over court should reinstate a ball")
	assert_eq(reinstated.speed, 600.0, "preserved_speed should propagate to the reinstated ball")
	assert_almost_eq(
		reinstated.linear_velocity.length(),
		600.0,
		0.001,
		"reinstated ball's velocity magnitude should match the preserved speed",
	)


func test_rack_slot_press_triggers_drag_pickup() -> void:
	_manager.take("ball_alpha")

	_rack.press_slot("ball_alpha")

	assert_true(_drag.is_dragging(), "rack slot press should start the drag gesture")
	assert_eq(_drag.get_held_key(), "ball_alpha")
