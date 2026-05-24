# gdlint:ignore = max-public-methods
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")

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
	_manager.economy.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
		if child is Ball:
			result.append(child)
	return result


func _loose_bodies_under_host() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
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
	# Step 5: venue-floor release routes through reconciler; the Ball lives in OUT_REST in the registry.
	assert_false(
		_manager.is_on_court("ball_alpha"), "rack-origin venue release does not flip on-court"
	)
	assert_true(
		_manager.is_loose_in_venue("ball_alpha"),
		"rack-origin venue release marks loose-in-venue so the rack filter hides the slot",
	)
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "venue release puts the Ball into the registry")
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST, "venue Ball is OUT_REST")
	assert_eq(_loose_bodies_under_host().size(), 0, "no HeldBody loose body left behind")


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
	# Step 3: the live Ball is the drag target across the gesture; no queue_free on grab.
	assert_true(
		is_instance_valid(live), "live ball must survive the grab (single-entity ball model)"
	)
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD, "grabbed ball transitions to OUT_HELD")
	assert_eq(
		_reconciler.get_ball_for_key("ball_alpha"),
		live,
		"reconciler keeps the same instance tracked through the gesture",
	)


func test_mid_rally_grab_then_release_over_court_reinstates_a_ball() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live_before: Ball = _reconciler.get_ball_for_key("ball_alpha")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame

	var court_point := Vector2(50, -25)
	var released: bool = _drag.attempt_release(court_point)

	assert_true(released)
	var reinstated: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(reinstated, "court release should keep the Ball tracked by the reconciler")
	assert_eq(reinstated, live_before, "same Ball instance survives the grab → court release")
	assert_eq(reinstated.global_position, court_point)
	assert_ne(
		reinstated.play_state,
		Ball.PlayState.OUT_HELD,
		"court release transitions the Ball out of OUT_HELD into PLAY",
	)


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

	# Step 5: rack-origin venue release produces an OUT_REST Ball in the registry, not a HeldBody.
	assert_false(_manager.is_on_court("ball_alpha"))
	assert_true(_manager.is_loose_in_venue("ball_alpha"))
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "Ball lives in the registry at the release point")
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST)
	assert_eq(ball.global_position, in_venue_out_of_court)
	assert_eq(_loose_bodies_under_host().size(), 0, "no HeldBody loose body left behind")


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


func test_rack_slot_press_triggers_drag_pickup() -> void:
	_manager.take("ball_alpha")

	_rack.press_slot("ball_alpha")

	assert_true(_drag.is_dragging(), "rack slot press should start the drag gesture")
	assert_eq(_drag.get_held_key(), "ball_alpha")


# --- grab_equipped_from_character (SH-405 reverse-equip path) -----------------------


func _add_equipment_to_manager(key: String) -> ItemDefinition:
	var equipment: ItemDefinition = ItemTestHelpersScript.make_ball_item(key)
	equipment.role = &"equipment"
	var typed_items: Array[ItemDefinition] = [equipment]
	for existing in _manager.items:
		typed_items.append(existing)
	_manager.items.assign(typed_items)
	_manager.take(key)
	return equipment


func _wire_character_drop_target() -> Area2D:
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	_drag.timeout_controller = timeout
	_drag.gear_rack = _rack
	_drag.gear_rack_drop_target = _drop_target
	var character_area: Area2D = _make_drop_target(Vector2(0, 0), Vector2(40, 80))
	_drag.set_character_drop_target(character_area)
	return character_area


func test_grab_equipped_from_character_spawns_held_body_and_keeps_equipped() -> void:
	_add_equipment_to_manager("gear_x")
	_manager.state.item_placements["gear_x"] = Placement.EQUIPPED
	_wire_character_drop_target()

	var ok: bool = _drag.grab_equipped_from_character("gear_x", Vector2.ZERO)

	assert_true(ok, "press on equipped art should start a drag")
	assert_true(_drag.is_dragging())
	assert_eq(_drag.get_held_key(), "gear_x")
	assert_eq(
		_manager.get_placement("gear_x"),
		Placement.EQUIPPED,
		"the item stays equipped throughout the gesture; only rack accept calls unequip",
	)


func test_grab_equipped_refuses_mid_rally() -> void:
	_add_equipment_to_manager("gear_z")
	_manager.state.item_placements["gear_z"] = Placement.EQUIPPED
	_wire_character_drop_target()

	var ball: Ball = _reconciler.adopt_stored("ball_alpha", Vector2.ZERO)
	ball.set_play_state(Ball.PlayState.PLAY_NORMAL)

	var ok: bool = _drag.grab_equipped_from_character("gear_z", Vector2.ZERO)

	assert_false(ok, "press on equipped art is refused while a ball is in play and timeout is idle")
	assert_false(_drag.is_dragging())


func test_grab_equipped_refuses_when_item_not_equipped() -> void:
	_add_equipment_to_manager("gear_y")
	# Item is owned but on the rack (STORED). Pressing the character has no source to grab from.
	_wire_character_drop_target()

	var ok: bool = _drag.grab_equipped_from_character("gear_y", Vector2.ZERO)

	assert_false(ok, "no equipped source -> refuse the grab")
	assert_false(_drag.is_dragging())


func test_grab_equipped_release_on_rack_unequips() -> void:
	_add_equipment_to_manager("gear_z")
	_manager.state.item_placements["gear_z"] = Placement.EQUIPPED
	_wire_character_drop_target()
	_drag.grab_equipped_from_character("gear_z", Vector2.ZERO)

	# Release over the gear rack drop target (mirrors _drop_target position).
	var rack_position: Vector2 = _drop_target.global_position
	# Move cursor past the commit-threshold first so the no-op gate doesn't swallow this.
	_drag._track_cursor_motion(rack_position)
	_drag._gesture_below_threshold = false

	var released: bool = _drag.attempt_release(rack_position)

	assert_true(released)
	assert_eq(
		_manager.get_placement("gear_z"),
		Placement.STORED,
		"drop on the rack must unequip the gear (placement returns to STORED)",
	)
	assert_false(_drag.is_dragging())


func test_grab_equipped_release_on_venue_floor_unequips() -> void:
	_add_equipment_to_manager("gear_v")
	_manager.state.item_placements["gear_v"] = Placement.EQUIPPED
	_wire_character_drop_target()
	_drag.grab_equipped_from_character("gear_v", Vector2.ZERO)
	_drag._gesture_below_threshold = false

	# Release inside the venue but outside any rack: venue catches as loose drop.
	var venue_floor := Vector2(0, 600)
	_drag.attempt_release(venue_floor)

	assert_ne(
		_manager.get_placement("gear_v"),
		Placement.EQUIPPED,
		"venue-loose drop on EQUIPPED routes through unequip; placement leaves EQUIPPED",
	)


func test_rack_drop_target_refuses_equipment_mid_rally() -> void:
	var area := _make_drop_target(Vector2(0, 0), Vector2(200, 200))
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)

	var rack_target: RackDropTarget = (
		load("res://scripts/items/drop_targets/rack_drop_target.gd").new()
	)
	rack_target.configure(_manager, area, &"equipment", timeout, _reconciler)

	_add_equipment_to_manager("gear_r")
	_manager.state.item_placements["gear_r"] = Placement.EQUIPPED

	# Setup case: nothing in play -> accepts.
	assert_true(
		rack_target.can_accept("gear_r", Vector2.ZERO),
		"equipment rack accepts when no ball is in PLAY",
	)

	# Spawn a ball in PLAY -> rally in progress -> refuses.
	var ball: Ball = _reconciler.adopt_stored("ball_alpha", Vector2.ZERO)
	ball.set_play_state(Ball.PlayState.PLAY_NORMAL)
	assert_false(
		rack_target.can_accept("gear_r", Vector2.ZERO),
		"equipment rack refuses while a rally is in progress",
	)


func test_grab_equipped_release_on_non_accepting_target_keeps_equipped() -> void:
	# Zero venue bounds disables the venue catch-all; every remaining built-in target refuses,
	# so placement stays EQUIPPED (only rack accept calls unequip).
	_add_equipment_to_manager("gear_w")
	_manager.state.item_placements["gear_w"] = Placement.EQUIPPED
	_drag.venue_bounds = Rect2()
	_wire_character_drop_target()
	_drag.grab_equipped_from_character("gear_w", Vector2.ZERO)
	_drag._gesture_below_threshold = false

	# Release inside the court (which rejects equipment-role) far from the gear rack.
	var released: bool = _drag.attempt_release(Vector2.ZERO)

	assert_false(released, "no target accepted -> gesture stays alive (release pending)")
	assert_eq(
		_manager.get_placement("gear_w"),
		Placement.EQUIPPED,
		"unaccepted release must NOT unequip the gear",
	)
