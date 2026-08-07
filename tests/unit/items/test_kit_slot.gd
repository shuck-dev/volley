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
	_slot.capacity = 1
	_slot.configure(_manager)
	add_child_autofree(_slot)


func test_can_accept_true_when_kit_has_room() -> void:
	assert_true(_slot.can_accept("kit_ball_1"))


func test_can_accept_false_when_kit_is_full() -> void:
	_manager.take("kit_ball")
	_manager.add_to_kit("kit_ball_1")

	assert_false(_slot.can_accept("other_ball_1"))


func test_can_accept_true_for_the_slots_own_occupant_even_when_full() -> void:
	_manager.take("kit_ball")
	_manager.add_to_kit("kit_ball_1")
	_slot.set_displayed_key("kit_ball_1", null)

	assert_true(
		_slot.can_accept("kit_ball_1"),
		"re-dropping onto the slot's own occupant should not be blocked by its own fullness",
	)


func test_accept_moves_the_ball_into_the_kit() -> void:
	_manager.take("kit_ball")

	_slot.accept("kit_ball_1")

	var kit_items: Array[String] = _manager.get_kit_items()
	assert_eq(kit_items.size(), 1)
	assert_eq(kit_items[0], "kit_ball_1")


func test_set_displayed_key_stores_the_key() -> void:
	_slot.set_displayed_key("kit_ball_1", null)

	assert_eq(_slot.get_displayed_key(), "kit_ball_1")
