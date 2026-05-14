## SH-332 regression coverage: post-Ride blockers (gear crash, venue duplicates, shop snap, wall pin).
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const HeldBodyScript: GDScript = preload("res://scripts/items/held_body.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _gear_rack: RackDisplay
var _drop_target: Area2D
var _gear_drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController


func _make_rack(role: StringName) -> RackDisplay:
	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = role
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)
	for index in 4:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	rack.slot_container = slot_container
	rack.configure(_manager)
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


func _make_equipment_item(key: String, with_shape: bool) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = key
	item.role = &"equipment"
	item.base_cost = 10
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = []
	item.art = ItemTestHelpersScript.stub_art()
	if with_shape:
		var shape := CircleShape2D.new()
		shape.radius = 8.0
		item.at_rest_shape = shape
	return item


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var gear_with_shape: ItemDefinition = _make_equipment_item("gear_alpha", true)
	var gear_no_shape: ItemDefinition = _make_equipment_item("gear_legacy", false)
	var typed_items: Array[ItemDefinition] = [ball_alpha, gear_with_shape, gear_no_shape]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(&"ball")
	_gear_rack = _make_rack(&"equipment")
	# Ball rack drop area off to the left, gear rack off to the right; a venue floor sits in the middle.
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))
	_gear_drop_target = _make_drop_target(Vector2(1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.gear_rack = _gear_rack
	_drag.gear_rack_drop_target = _gear_drop_target
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


func _loose_bodies_under_host() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
		if child is HeldBody:
			result.append(child)
	return result


func _rest_balls_under_host() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
		if child is Ball and (child as Ball).play_state == Ball.PlayState.OUT_REST:
			result.append(child)
	return result


# Bug 1: gear-rack press on an item without at_rest_shape must not crash.
func test_grab_from_rack_refuses_equipment_without_shape() -> void:
	_manager.take("gear_legacy")
	var ok: bool = _drag.grab_from_rack("gear_legacy")
	assert_false(
		ok, "grab_from_rack returns false rather than crashing on a shapeless equipment item"
	)
	assert_false(_drag.is_dragging(), "no held body should exist after a refused grab")


# Bug 1: a properly authored equipment item with at_rest_shape grabs cleanly through the gear-rack path.
func test_grab_from_rack_accepts_equipment_with_shape() -> void:
	_manager.take("gear_alpha")
	var ok: bool = _drag.grab_from_rack("gear_alpha")
	assert_true(
		ok, "equipment with an authored at_rest_shape grabs through the same path as a ball"
	)
	assert_true(_drag.is_dragging())
	assert_eq(_drag.get_held_key(), "gear_alpha")


# Bug 2: a venue release marks the key loose-in-venue so _on_drop_completed does not reveal the rack slot.
func test_venue_release_does_not_reveal_rack_slot() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	# Force the gesture above the no-op threshold so the venue branch can fire.
	_drag._gesture_below_threshold = false

	# Release outside the court rect but inside the venue rect; the venue drop target should accept.
	var venue_floor := Vector2(800, 600)
	var released: bool = _drag.attempt_release(venue_floor)
	assert_true(released, "venue floor release accepted by VenueDropTarget")
	assert_false(_drag.is_dragging(), "gesture finalised on release")
	# ItemManager carries the loose-in-venue overlay; rack filter respects it via get_kit_items.
	assert_true(
		_manager.is_loose_in_venue("ball_alpha"),
		"loose-in-venue placement prevents _on_drop_completed from revealing the rack slot",
	)
	assert_eq(
		_rack.get_displayed_keys().find("ball_alpha"),
		-1,
		"rack does not render a slot for a loose-in-venue key",
	)
	# Step 5: the canonical instance is a Ball in OUT_REST under the reconciler.
	assert_eq(_loose_bodies_under_host().size(), 0, "no HeldBody loose body lingers post-release")
	assert_eq(
		_rest_balls_under_host().size(),
		1,
		"exactly one OUT_REST Ball persists at the release point"
	)


# Edith's regression: spawn_purchased_at on a venue release marks loose-in-venue so the gear rack
# does not render a slot for the freshly-purchased equipment alongside the loose body.
func test_purchase_spawn_at_venue_does_not_render_rack_slot() -> void:
	# Take the equipment so the rack would otherwise pick it up after the level-changed signal.
	_manager.take("gear_alpha")
	var venue_floor := Vector2(800, 600)
	var spawned: bool = _drag.spawn_purchased_at("gear_alpha", venue_floor, Vector2.ZERO)
	assert_true(spawned, "spawn_purchased_at routes the venue release to a loose body")
	assert_true(
		_manager.is_loose_in_venue("gear_alpha"),
		"placement overlay flips to LOOSE_IN_VENUE on purchase-spawn",
	)
	assert_eq(
		_gear_rack.get_displayed_keys().find("gear_alpha"),
		-1,
		"gear rack does not render a slot for the loose-in-venue equipment",
	)
	assert_eq(
		_loose_bodies_under_host().size(),
		1,
		"exactly one loose body lives at the release point",
	)


# Step 5: re-grabbing the OUT_REST Ball clears the LOOSE_IN_VENUE overlay so a non-venue release restores the slot.
func test_regrab_clears_loose_in_venue_overlay() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	_drag._gesture_below_threshold = false
	_drag.attempt_release(Vector2(800, 600))
	assert_true(_manager.is_loose_in_venue("ball_alpha"))

	var resting_balls: Array = _rest_balls_under_host()
	assert_eq(resting_balls.size(), 1)
	var ball: Ball = resting_balls[0]
	# Synthesise the grab signal the Ball's grab area would emit on press.
	ball.grabbed.emit(ball)
	assert_false(
		_manager.is_loose_in_venue("ball_alpha"),
		"re-grabbing an OUT_REST Ball clears the placement overlay",
	)


# Step 5 obsoletes the "free the loose HeldBody" test — the loose Ball lives in the registry
func test_clear_loose_in_venue_restores_rack_filter() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	_drag._gesture_below_threshold = false
	_drag.attempt_release(Vector2(800, 600))
	assert_true(_manager.is_loose_in_venue("ball_alpha"))

	_manager.clear_loose_in_venue("ball_alpha")
	assert_false(
		_manager.is_loose_in_venue("ball_alpha"),
		"clearing the placement overlay returns the rack slot to the kit view",
	)


# Bug 4: a fresh attempt_release at a valid target resolves the gesture and clears _release_pending.
func test_release_pending_resolves_when_cursor_reaches_valid_target() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	_drag._gesture_below_threshold = false
	_drag._release_pending = true

	var court_point := Vector2(0, 0)
	var resolved: bool = _drag.attempt_release(court_point)
	assert_true(resolved, "moving to a valid drop point resolves the pending release")
	assert_false(_drag.is_dragging(), "gesture finalises once a target accepts")
	assert_false(
		_drag._release_pending, "_release_pending clears with the rest of the gesture state"
	)
