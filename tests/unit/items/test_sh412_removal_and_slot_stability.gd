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
	_manager.economy.soul_balance = 10000

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
	var alpha_1 := "ball_alpha_1"
	var beta_1 := "ball_beta_1"
	var alpha_slot: int = _manager.get_rack_slot_index(alpha_1)
	_manager.activate(alpha_1)
	_manager.activate(beta_1)
	_manager.deactivate(alpha_1)
	_manager.deactivate(beta_1)

	_manager.remove_level(beta_1)

	assert_eq(_manager.get_level(beta_1), 0, "ball_beta is fully removed")
	assert_eq(_manager.get_rack_slot_index(beta_1), -1, "removed ball owns no rack slot")
	assert_eq(
		_manager.get_rack_slot_index(alpha_1),
		alpha_slot,
		"surviving ball keeps its original slot",
	)
	assert_null(_reconciler.get_ball_for_key(beta_1), "no live ball survives for the removed key")
	assert_not_null(_reconciler.get_ball_for_key(alpha_1), "surviving ball stays tracked")


func test_surviving_balls_keep_their_slot_indices_after_a_removal() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	var alpha_1 := "ball_alpha_1"
	var beta_1 := "ball_beta_1"
	var alpha_slot: int = _manager.get_rack_slot_index(alpha_1)
	var beta_slot: int = _manager.get_rack_slot_index(beta_1)

	_manager.remove_level(alpha_1)

	assert_eq(
		_manager.get_rack_slot_index(beta_1),
		beta_slot,
		"the other ball does not shuffle into the freed slot",
	)
	assert_ne(beta_slot, alpha_slot, "precondition: the two balls held distinct slots")


func test_returning_ball_fills_the_lowest_free_slot() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	var alpha_1 := "ball_alpha_1"
	var beta_1 := "ball_beta_1"
	var beta_slot: int = _manager.get_rack_slot_index(beta_1)
	assert_ne(beta_slot, 0, "precondition: beta's original slot was not the lowest")

	# Free both slots, then return beta first: it fills the lowest free slot, not its prior one.
	_manager.release_rack_slot(alpha_1)
	_manager.release_rack_slot(beta_1)
	assert_eq(
		_manager.get_rack_slot_index(beta_1), -1, "held ball frees its slot during the gesture"
	)

	_manager.reassign_rack_slot(beta_1)

	assert_eq(
		_manager.get_rack_slot_index(beta_1),
		0,
		"a returning ball fills the lowest free slot (FIFO), not its prior one",
	)
