# gdlint:ignore = max-public-methods
## SH-412 full removal retires the ball and frees its slot; surviving and restored balls keep their slot.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var ball_beta: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_beta")
	var typed_items: Array[ItemDefinition] = [ball_alpha, ball_beta]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 10000

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)


func _make_rack() -> RackDisplay:
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
	rack.configure(_manager)
	rack.configure_reconciler(_reconciler)
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


## True when the rebuilt slot for `item_key` is present and visible (pickable CanvasItem).
func _slot_visible_for(rack: RackDisplay, item_key: String) -> bool:
	var slot: Node = rack.slot_container.get_node_or_null("Slot_%s" % item_key)
	return slot != null and (slot as CanvasItem).visible


func test_removing_one_ball_leaves_the_other_slot_untouched() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	var alpha_slot: int = _manager.get_rack_slot_index("ball_alpha")
	_manager.activate("ball_alpha")
	_manager.activate("ball_beta")
	_manager.deactivate("ball_alpha")
	_manager.deactivate("ball_beta")

	_manager.remove_level("ball_beta")

	assert_eq(_manager.get_level("ball_beta"), 0, "ball_beta is fully removed")
	assert_eq(_manager.get_rack_slot_index("ball_beta"), -1, "removed ball owns no rack slot")
	assert_eq(
		_manager.get_rack_slot_index("ball_alpha"),
		alpha_slot,
		"surviving ball keeps its original slot",
	)
	assert_null(
		_reconciler.get_ball_for_key("ball_beta"), "no live ball survives for the removed key"
	)
	assert_not_null(_reconciler.get_ball_for_key("ball_alpha"), "surviving ball stays tracked")


func test_surviving_balls_keep_their_slot_indices_after_a_removal() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	var alpha_slot: int = _manager.get_rack_slot_index("ball_alpha")
	var beta_slot: int = _manager.get_rack_slot_index("ball_beta")

	_manager.remove_level("ball_alpha")

	assert_eq(
		_manager.get_rack_slot_index("ball_beta"),
		beta_slot,
		"the other ball does not shuffle into the freed slot",
	)
	assert_ne(beta_slot, alpha_slot, "precondition: the two balls held distinct slots")


func test_returning_ball_fills_the_lowest_free_slot() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	var beta_slot: int = _manager.get_rack_slot_index("ball_beta")
	assert_ne(beta_slot, 0, "precondition: beta's original slot was not the lowest")

	# Free both slots, then return beta first: it fills the lowest free slot, not its prior one.
	_manager.release_rack_slot("ball_alpha")
	_manager.release_rack_slot("ball_beta")
	assert_eq(
		_manager.get_rack_slot_index("ball_beta"), -1, "held ball frees its slot during the gesture"
	)

	_manager.reassign_rack_slot("ball_beta")

	assert_eq(
		_manager.get_rack_slot_index("ball_beta"),
		0,
		"a returning ball fills the lowest free slot (FIFO), not its prior one",
	)


## SH-412 regression: with two stored balls, the second slot must be indexed, visible, backed by a
## live ball, and grabbable; clicking it used to do nothing because its slot rebuilt invisible.
func test_second_stored_ball_is_indexed_visible_and_grabbable() -> void:
	_reconciler.ball_rack = _make_rack()
	var rack: RackDisplay = _reconciler.ball_rack
	var drop_target: Area2D = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	var drag: ItemDragController = ItemDragControllerScript.new()
	drag.configure(_manager, rack, drop_target, _reconciler)
	drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(drag)

	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	rack.refresh()

	assert_true(
		_manager.get_rack_slot_index("ball_beta") >= 0, "second stored ball owns a rack slot"
	)
	assert_true(_slot_visible_for(rack, "ball_beta"), "second stored ball's slot is visible")
	assert_not_null(
		_reconciler.get_ball_for_key("ball_beta"), "second stored ball is backed by a live ball"
	)

	var grabbed: bool = drag.grab_from_rack("ball_beta")
	assert_true(grabbed, "the second stored ball is grabbable")
	assert_eq(drag.get_held_key(), "ball_beta", "the grab holds the second ball")


## SH-412 regression: assigning the second ball's slot AFTER the rack is built must re-render the
## rack through the rack_slots_changed signal alone (no manual refresh), so both slots end up
## visible, pickable, and grabbable. Proves the signal wiring, not refresh() called by the test.
func test_second_slot_assignment_signal_refreshes_the_rack() -> void:
	# Awaited: the rack connects rack_slots_changed deferred (see RackDisplay._ready), so the
	# signal-driven refresh lands on the next idle frame, not synchronously.
	_reconciler.ball_rack = _make_rack()
	var rack: RackDisplay = _reconciler.ball_rack
	var drop_target: Area2D = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	var drag: ItemDragController = ItemDragControllerScript.new()
	drag.configure(_manager, rack, drop_target, _reconciler)
	drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(drag)

	# Own both balls, then free the second's slot so the rack renders only the first. This isolates
	# the slot-map signal: reassign_rack_slot emits rack_slots_changed alone, with no level or
	# placement change to mask it. Mirrors base_ball going slot -1 -> 1 as it becomes stored.
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	_manager.release_rack_slot("ball_beta")
	await get_tree().process_frame
	assert_eq(rack.get_displayed_keys().size(), 1, "precondition: rack shows only the first ball")

	# Reassign the second ball's slot purely through the API. The rack must re-render off the
	# rack_slots_changed signal, never a manual refresh() here.
	_manager.reassign_rack_slot("ball_beta")
	await get_tree().process_frame

	var displayed: Array[String] = rack.get_displayed_keys()
	assert_true(displayed.has("ball_alpha"), "signal refresh kept the first ball displayed")
	assert_true(displayed.has("ball_beta"), "signal refresh added the second ball's slot")
	assert_true(_slot_visible_for(rack, "ball_alpha"), "first slot stays visible and pickable")
	assert_true(_slot_visible_for(rack, "ball_beta"), "second slot is visible and pickable")

	var grabbed: bool = drag.grab_from_rack("ball_beta")
	assert_true(grabbed, "the signal-rendered second slot is grabbable")
	assert_eq(drag.get_held_key(), "ball_beta", "the grab holds the second ball")


## SH-412 regression: a grab+restore cycle on the second ball returns its slot visible and pickable.
func test_second_ball_slot_returns_visible_after_grab_and_restore() -> void:
	_reconciler.ball_rack = _make_rack()
	var rack: RackDisplay = _reconciler.ball_rack
	var drop_target: Area2D = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	var drag: ItemDragController = ItemDragControllerScript.new()
	drag.configure(_manager, rack, drop_target, _reconciler)
	drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(drag)

	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	rack.refresh()
	var beta_slot: int = _manager.get_rack_slot_index("ball_beta")
	var grab_origin: Vector2 = _reconciler.get_ball_for_key("ball_beta").global_position

	assert_true(drag.grab_from_rack("ball_beta"), "precondition: second ball grabbed")
	# Press-release without movement at the grab origin: a rack-origin gesture restores to its slot.
	drag.attempt_release(grab_origin)

	assert_false(drag.is_dragging(), "gesture finalised after restore")
	assert_eq(
		_manager.get_rack_slot_index("ball_beta"),
		beta_slot,
		"restored second ball reclaims a rack slot",
	)
	assert_not_null(_reconciler.get_ball_for_key("ball_beta"), "restored ball stays tracked")
	assert_true(_slot_visible_for(rack, "ball_beta"), "restored slot is visible and pickable again")
