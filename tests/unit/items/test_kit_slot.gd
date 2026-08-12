extends GutTest

const KitSlotScene: PackedScene = preload("res://scenes/kit_slot.tscn")

var _manager: Node
var _slot: KitSlot


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	var ball_item := BallDefinition.new()
	ball_item.key = "kit_ball"
	ball_item.base_cost = 100
	ball_item.cost_scaling = 2.0
	ball_item.max_level = 3
	_manager.items.assign([ball_item])
	_manager.economy.soul_balance = 10000

	_slot = KitSlotScene.instantiate()
	_slot.slot_index = 0
	_slot.configure(_manager)
	add_child_autofree(_slot)


func test_can_accept_true_when_slot_is_empty() -> void:
	assert_true(_slot.can_accept("kit_ball_1"))


func test_can_accept_false_when_slot_holds_a_different_ball() -> void:
	_manager.take("kit_ball")
	_manager.add_to_kit("kit_ball_1", 0)

	assert_false(_slot.can_accept("other_ball_1"))


func test_can_accept_true_for_the_slots_own_occupant() -> void:
	_manager.take("kit_ball")
	_manager.add_to_kit("kit_ball_1", 0)

	assert_true(
		_slot.can_accept("kit_ball_1"),
		"re-dropping onto the slot's own occupant should not be blocked",
	)


func test_accept_moves_the_ball_into_this_slot() -> void:
	_manager.take("kit_ball")

	_slot.accept("kit_ball_1")

	assert_eq(_manager.get_ball_in_kit_slot(0), "kit_ball_1")


func test_can_accept_true_when_a_different_slot_is_occupied() -> void:
	_manager.take("kit_ball")
	_manager.add_to_kit("kit_ball_1", 1)

	assert_true(
		_slot.can_accept("kit_ball_1"),
		"slot 0 must stay open regardless of what slot 1 holds",
	)
