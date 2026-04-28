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


func test_expansion_ring_fallback_widens_after_hold_window() -> void:
	# The find-accepting-target helper accepts a scale factor; both strict (1.0) and
	# widened (1.5) probes accept on an empty court, so the expansion-ring path is wired
	# end-to-end without crashing.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	_drag._gesture_below_threshold = false
	_drag._expansion_started_at = (
		float(Time.get_ticks_msec()) / 1000.0 - _drag.EXPANSION_RING_HOLD_S - 0.05
	)
	var target_strict: DropTarget = _drag._find_accepting_target("ball_alpha", Vector2(0, 0), 1.0)
	assert_not_null(target_strict, "strict probe accepts an empty court")
	var target_widened: DropTarget = _drag._find_accepting_target("ball_alpha", Vector2(0, 0), 1.5)
	assert_not_null(target_widened, "widened probe also accepts an empty court")


func test_expansion_ring_cancel_after_two_holds_fails_to_source() -> void:
	# Push the expansion timer past 2x the hold window: triggers cancel-to-source.
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	_drag._gesture_below_threshold = false
	_drag._mouse_button_down = false
	_drag._expansion_started_at = (
		float(Time.get_ticks_msec()) / 1000.0 - _drag.EXPANSION_RING_HOLD_S * 2.0 - 0.1
	)
	_drag._cancel_to_source()
	assert_false(_drag.is_dragging(), "cancel-to-source frees the held token")


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
	# An empty-court position is a valid target; mouse-down (still grabbing) so hover
	# feedback applies (not the auto-commit branch).
	_drag._mouse_button_down = true
	_drag._update_hover_feedback(Vector2(0, 0))
	assert_ne(token.scale, Vector2(1.5, 1.5), "scale lifts when hovering a valid target")
