## SH-412 full removal retires the ball and frees its slot; surviving and restored balls keep their slot.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
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


func test_held_ball_returns_to_its_original_slot() -> void:
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	var beta_slot: int = _manager.get_rack_slot_index("ball_beta")

	# Free the lower slot too, so lowest-free would hand beta a different index than it had.
	_manager.release_rack_slot("ball_alpha")
	_manager.release_rack_slot("ball_beta")
	assert_eq(
		_manager.get_rack_slot_index("ball_beta"), -1, "held ball frees its slot during the gesture"
	)

	_manager.reassign_rack_slot("ball_beta")

	assert_eq(
		_manager.get_rack_slot_index("ball_beta"),
		beta_slot,
		"a restored ball returns to its original slot, not the lowest free one",
	)
	assert_ne(beta_slot, 0, "precondition: beta's original slot was not the lowest")
