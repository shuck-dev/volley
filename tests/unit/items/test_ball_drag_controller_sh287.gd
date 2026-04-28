## SH-287: BallDragController behaviours unique to the body-projection refactor.
## Splits from test_ball_drag_controller.gd to keep each suite under the public-method cap.
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


# --- SH-287 ACs: invalid release leaves the gesture open until a target accepts ----


func test_invalid_release_leaves_gesture_open_when_no_target_accepts() -> void:
	# Build a controller with NO registered targets (all four exports left null) so
	# every release fails. The held token must continue following the cursor.
	var drag: BallDragController = BallDragControllerScript.new()
	drag.configure(_manager, null, null, null)
	add_child_autofree(drag)

	_manager.take("ball_alpha")
	# Force the held-token state without going through grab_from_rack (which checks rack).
	drag._spawn_held_token("ball_alpha", Vector2.ZERO, false)
	drag._mouse_button_down = false
	drag._gesture_below_threshold = false

	var released: bool = drag.attempt_release(Vector2(50, 50))
	assert_false(released, "no target accepts -> gesture stays open")
	assert_true(drag.is_dragging(), "held token continues to follow the cursor")


# --- SH-287 ACs: expansion-ring fallback after the strict pass holds for ~250 ms ---


func test_expansion_ring_scale_genuinely_widens_the_probe() -> void:
	# Plumbs scale_factor through end-to-end: place a wall just outside the ball's strict
	# radius so the strict probe (1.0) clears, but the 1.5x widened probe overlaps the wall
	# and rejects. Without this distinguishing setup, both probes pass on an empty court and
	# the test couldn't tell scale 1.0 from scale 1.5.
	var ball_def: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_distinguishing")
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	ball_def.at_rest_shape = circle
	_manager.items.assign([ball_def] as Array[ItemDefinition])

	# Wall sits at (25, 0) with size 10x10; its left edge is at x=20.
	# Probe candidate position (0, 0): strict radius 10 reaches x=10 (clear);
	# widened radius 15 reaches x=15 (still clear). Move the wall closer.
	# Use wall left edge at x=14: strict reach x=10 clears; widened reach x=15 overlaps.
	var wall := StaticBody2D.new()
	wall.global_position = Vector2(19, 0)  # half-size 5 -> left edge at x=14
	var wall_collision := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(10, 10)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	_host.add_child(wall)
	# Two physics frames so the static body's RID lands in the space state.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Re-build the controller so its CourtDropTarget binds to _host's world.
	var drag: BallDragController = BallDragControllerScript.new()
	drag.configure(_manager, _rack, _drop_target, _reconciler)
	drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	_host.add_child(drag)

	var strict: DropTarget = drag._find_accepting_target("ball_distinguishing", Vector2.ZERO, 1.0)
	var widened: DropTarget = drag._find_accepting_target("ball_distinguishing", Vector2.ZERO, 1.5)
	assert_not_null(strict, "strict 1.0x probe clears the wall (radius 10 vs gap 14)")
	# The widened probe must reject because the 1.5x radius (15) crosses the wall edge (14).
	# This is the assertion that distinguishes scale 1.0 from scale 1.5.
	assert_true(
		widened == null or not (widened is CourtDropTarget),
		"widened 1.5x probe overlaps the wall and rejects (or falls through to a non-court target)",
	)


func test_expansion_ring_fallback_path_runs_on_empty_court() -> void:
	# Sanity: with no obstacles, both strict and widened probes accept. Pinned separately so
	# a regression that breaks the expansion-ring code path is caught even when no wall is
	# present.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	var target_strict: DropTarget = _drag._find_accepting_target("ball_alpha", Vector2(0, 0), 1.0)
	assert_not_null(target_strict, "strict probe accepts an empty court")
	var target_widened: DropTarget = _drag._find_accepting_target("ball_alpha", Vector2(0, 0), 1.5)
	assert_not_null(target_widened, "widened probe also accepts an empty court")


func test_expansion_ring_cancel_after_two_holds_fails_to_source() -> void:
	# Drives _update_expansion_state (the production caller of _cancel_to_source) with a
	# release point outside both the court and venue so neither strict nor widened probes
	# accept. Pushing the timer past 2x expansion_ring_hold_s must cancel the gesture.
	# This test fails if the timer never invokes cancel.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	_drag._gesture_below_threshold = false
	_drag._mouse_button_down = false
	# Push the start time back so held_duration >= expansion_ring_hold_s * 2.
	_drag._expansion_started_at = (
		float(Time.get_ticks_msec()) / 1000.0 - _drag.expansion_ring_hold_s * 2.0 - 0.1
	)
	# Position outside both court (1200x800 around origin) and venue (4000x2400) so no
	# target ever accepts -> _update_expansion_state must fall to _cancel_to_source.
	var off_screen: Vector2 = Vector2(99999, 99999)
	assert_true(_drag.is_dragging(), "precondition: held token alive before expansion tick")
	_drag._update_expansion_state(off_screen)
	assert_false(
		_drag.is_dragging(),
		"_update_expansion_state must cancel-to-source after 2x hold window with no target",
	)


func test_expansion_state_does_not_cancel_within_first_window() -> void:
	# Within expansion_ring_hold_s of expansion-start, _update_expansion_state must not
	# cancel. Pins the boundary so a regression that fires cancel on the first frame is
	# caught.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	_drag._gesture_below_threshold = false
	_drag._mouse_button_down = false
	# Started just now: held_duration is below the first hold window.
	_drag._expansion_started_at = float(Time.get_ticks_msec()) / 1000.0
	_drag._update_expansion_state(Vector2(99999, 99999))
	assert_true(_drag.is_dragging(), "no cancel within the first hold window")


func test_expansion_state_commits_when_widened_probe_accepts() -> void:
	# Strict probe fails (off-court) but widened probe accepts (venue catches it). The
	# expansion path should commit via attempt_release rather than cancel.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	_drag._gesture_below_threshold = false
	_drag._mouse_button_down = false
	_drag._expansion_started_at = (
		float(Time.get_ticks_msec()) / 1000.0 - _drag.expansion_ring_hold_s - 0.05
	)
	# Position inside the venue but on the court (so both probes succeed via court target);
	# this exercises the widened-probe-accepts branch in _update_expansion_state which
	# re-runs attempt_release and commits.
	_drag._update_expansion_state(Vector2(0, 0))
	assert_false(_drag.is_dragging(), "widened-accept branch commits the gesture")


# --- SH-320 regression: shop-to-court drag spawns a live ball at the release point --


func test_shop_purchase_routes_to_court_via_drag_controller() -> void:
	# spawn_purchased_at runs the same target poll the held-gesture uses, so a clear
	# court position spawns a live ball directly through the reconciler.
	var spawned: bool = _drag.spawn_purchased_at("ball_alpha", Vector2(40, -20), Vector2(150, 0))
	assert_true(spawned, "court target accepts the post-purchase release point")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(
		ball, "reconciler should own the new live ball after the purchase routes to court"
	)
	assert_eq(ball.global_position, Vector2(40, -20))


func test_shop_purchase_falls_through_when_no_target_accepts() -> void:
	# Outside both court and venue: no target accepts and spawn_purchased_at returns false
	# so the shop's regular fallback (rack token) covers it.
	var spawned: bool = _drag.spawn_purchased_at("ball_alpha", Vector2(99999, 99999), Vector2(0, 0))
	assert_false(spawned, "way-off-screen position falls through the target poll")


# --- SH-287 ACs: hover feedback bumps held-token scale over a valid target ---------


func test_hover_feedback_bumps_held_token_scale_over_valid_target() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var token: Node2D = _drag.get_held_token()
	assert_not_null(token, "precondition: held token spawned")
	var definition: ItemDefinition = _drag._get_item_definition("ball_alpha")
	var base_scale: Vector2 = definition.token_scale
	# An empty-court position is a valid target; mouse-down (still grabbing) so hover
	# feedback applies (not the auto-commit branch).
	_drag._mouse_button_down = true
	_drag._update_hover_feedback(Vector2(0, 0))
	# Pin the exact lifted scale so a regression that shrinks the token (or zeroes the bump)
	# fails the assertion. assert_ne against an arbitrary value would let any non-equal
	# regression slip through.
	var expected_lifted: Vector2 = base_scale * _drag.HOVER_SCALE_BUMP
	assert_eq(token.scale, expected_lifted, "hover lifts to base_scale * HOVER_SCALE_BUMP exactly")
	assert_eq(token.modulate, _drag.HOVER_MODULATE, "hover modulate matches the constant")


func test_hover_feedback_resets_to_base_scale_when_no_target_accepts() -> void:
	# Off-court, off-venue release point: no target accepts; hover feedback must reset the
	# held token to its base (definition-authored) scale and neutral modulate. Pins the
	# inverse of the lift so a regression that leaves stale lift state across frames fails.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var token: Node2D = _drag.get_held_token()
	var definition: ItemDefinition = _drag._get_item_definition("ball_alpha")
	var base_scale: Vector2 = definition.token_scale
	_drag._mouse_button_down = true
	# First, lift, then drop hover.
	_drag._update_hover_feedback(Vector2(0, 0))
	_drag._update_hover_feedback(Vector2(99999, 99999))
	assert_eq(token.scale, base_scale, "off-target hover resets to base token_scale")
	assert_eq(token.modulate, _drag.NEUTRAL_MODULATE, "off-target hover resets modulate")
