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
	_manager._progression.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(&"ball")
	_gear_rack = _make_rack(&"equipment")
	# Ball rack drop area off to the left, gear rack off to the right; a venue floor sits in the middle.
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))
	_gear_drop_target = _make_drop_target(Vector2(1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
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
	for child in _host.get_children():
		if child is HeldBody:
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
	# The loose-in-venue tracker holds the key; rack stays hidden so the body in the world is the only instance.
	assert_true(
		_drag._loose_in_venue_keys.has("ball_alpha"),
		"loose-in-venue marker prevents _on_drop_completed from revealing the rack slot",
	)
	# A loose body must exist under the reconciler ball-host as the canonical instance.
	assert_eq(
		_loose_bodies_under_host().size(), 1, "exactly one loose body persists at the release point"
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
