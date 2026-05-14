## Dragged-gravity state-machine transitions; canon at designs/01-prototype/design/21-ball-dynamics.md.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

const AUTHORED_RADIUS: float = 9.0

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController
var _authored_shape: CircleShape2D


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
	# Pin an authored at_rest_shape so a future fallback-to-default-circle regression fails here.
	_authored_shape = CircleShape2D.new()
	_authored_shape.radius = AUTHORED_RADIUS
	ball_alpha.at_rest_shape = _authored_shape
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


func test_grab_spawns_a_rigid_body_held_in_kinematic_freeze() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var body: HeldBody = _drag.get_held_body()
	assert_not_null(body, "held body is a HeldBody (RigidBody2D), not a plain Node2D")
	assert_true(body.freeze, "held body stays frozen-kinematic so the controller drives position")
	assert_eq(
		body.freeze_mode,
		RigidBody2D.FREEZE_MODE_KINEMATIC,
		"freeze_mode is kinematic so position writes do not fight the solver",
	)
	assert_eq(body.gravity_scale, 0.0, "gravity is zero during the lift; engages on go_loose")
	assert_eq(body.phase, HeldBody.Phase.LIFTING)
	var collision: CollisionShape2D = body.get_node("Collision") as CollisionShape2D
	assert_true(
		collision.shape is CircleShape2D, "held body uses the definition's authored shape type"
	)
	var circle: CircleShape2D = collision.shape
	assert_almost_eq(
		circle.radius,
		AUTHORED_RADIUS,
		0.001,
		"held body collision radius matches the authored at_rest_shape, not a fallback default",
	)


func test_lift_settle_promotes_phase_and_arms_loose_gravity() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha", Vector2(0, 0))
	var body: HeldBody = _drag.get_held_body()
	_drag._grab_ease_elapsed = _drag.grab_ease_duration_s
	_drag._apply_grab_ease(_drag._grab_ease_progress(), Vector2(50, 50))
	assert_eq(body.phase, HeldBody.Phase.HELD, "lift settle promotes phase to HELD")
	assert_eq(body.gravity_scale, 0.0, "gravity stays off while the body is cursor-pinned")
	assert_gt(body.loose_gravity_scale, 0.0, "loose gravity is armed for a future floor release")


func _seed_release_velocity(start: Vector2, end: Vector2) -> void:
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": start})
	_drag._cursor_samples.append({"time": 0.04, "position": end})


func test_release_over_court_frees_held_body_and_spawns_active_movement_ball() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame
	var held: HeldBody = _drag.get_held_body()
	assert_not_null(held)
	_seed_release_velocity(Vector2.ZERO, Vector2(80, 0))

	var court_point := Vector2(50, 25)
	assert_true(_drag.attempt_release(court_point))
	await get_tree().process_frame

	assert_false(is_instance_valid(held), "held body is freed after a court release")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "court release spawns the rally Ball")
	assert_eq(ball.gravity_scale, 0.0, "active-movement has gravity off (frictionless rally)")


func test_release_into_venue_floor_lands_ball_in_out_rest() -> void:
	# Step 5: rack-origin venue release transitions to an OUT_REST Ball, not a loose HeldBody.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	var loose_position := Vector2(1500, 100)
	assert_true(_drag.attempt_release(loose_position))
	assert_eq(_loose_bodies_under_host().size(), 0, "no HeldBody loose body lingers post-release")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "Ball lives in the registry at the release position")
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST)
	assert_false(ball.freeze)
	assert_gt(ball.gravity_scale, 0.0)
	assert_false(_manager.is_on_court("ball_alpha"))
	assert_true(_manager.is_loose_in_venue("ball_alpha"))


func test_mid_rally_grab_keeps_same_ball_in_out_held_with_velocity_carryover() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live)
	live.global_position = Vector2(75, 30)
	# Use a speed within [min_speed, max_speed] so the speed-limit clamp in
	# BallEffectProcessor leaves the carryover untouched on the next physics tick.
	var carry_speed: float = live.min_speed * 1.2
	live.speed = carry_speed

	assert_true(_drag.grab_live_ball("ball_alpha", false))

	# Step 3: no HeldBody spawn on a live grab; the Ball is the drag target.
	assert_null(_drag.get_held_body(), "live grab does not spawn a HeldBody")
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD, "grabbed ball transitions to OUT_HELD")
	assert_eq(live.global_position, Vector2(75, 30), "ball stays at its pre-grab world position")
	assert_true(live.freeze, "OUT_HELD freezes the body so the controller drives position")
	assert_eq(live.collision_layer, 0, "OUT_HELD suppresses collision")
	await get_tree().process_frame

	_seed_release_velocity(Vector2(75, 30), Vector2(155, 30))
	assert_true(_drag.attempt_release(Vector2(50, 25)))
	await get_tree().process_frame
	var released: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(released, live, "same Ball instance survives the grab → court release")
	assert_almost_eq(released.linear_velocity.length(), carry_speed, 0.5)


func test_out_rest_ball_has_grab_area_enabled() -> void:
	# Step 5: the OUT_REST Ball's grab area routes pickups through the live-grab path.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame
	assert_true(_drag.attempt_release(Vector2(1500, 100)), "venue release succeeds")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "venue release puts a Ball into the registry")
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST)
	assert_not_null(ball.grab_area, "Ball ships with a grab area for re-grab")


func test_out_rest_ball_press_re_grabs_through_live_grab_path() -> void:
	# Step 5: pressing an OUT_REST Ball routes through grab_live_ball, preserving identity.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame
	assert_true(_drag.attempt_release(Vector2(1500, 100)))
	var resting: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(resting)
	assert_eq(resting.play_state, Ball.PlayState.OUT_REST)

	# Synthesise the grab signal the ball's grab area would emit.
	resting.grabbed.emit(resting)
	await get_tree().process_frame

	assert_eq(
		_reconciler.get_ball_for_key("ball_alpha"),
		resting,
		"OUT_REST re-grab keeps the same Ball instance — live-grab path",
	)
	assert_eq(resting.play_state, Ball.PlayState.OUT_HELD, "re-grab transitions to OUT_HELD")
	assert_true(resting.freeze, "OUT_HELD freezes the body for controller follow")
	assert_false(
		_manager.is_loose_in_venue("ball_alpha"),
		"grab clears the loose-in-venue overlay so a later non-venue release restores the rack slot",
	)


func test_grab_live_ball_excludes_held_ball_rid_from_court_projection() -> void:
	# Step 3: the held Ball is the same instance across the gesture; its RID must be excluded from
	# the court projection so the next release does not self-overlap and snap off-court.
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	live.global_position = Vector2(0, 0)
	var live_rid: RID = live.get_rid()

	assert_true(_drag.grab_live_ball("ball_alpha", false))

	var court_target: CourtDropTarget = null
	for target in _drag.get_registered_targets():
		if target is CourtDropTarget:
			court_target = target
			break
	assert_not_null(court_target, "controller registers a CourtDropTarget")
	assert_true(
		court_target._exclude_rids.has(live_rid),
		"the held Ball's RID is excluded from the court projection during the grab",
	)
