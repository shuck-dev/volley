extends GutTest

const ClearanceBoxScene: PackedScene = preload("res://scenes/clearance_box.tscn")


class TestCanAccept:
	extends GutTest

	var _box: ClearanceBox
	var _definition: ItemDefinition
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_definition = _item_manager.items[0]
		_box = ClearanceBoxScene.instantiate()
		_box._item_manager = _item_manager
		add_child_autofree(_box)

	func test_returns_false_when_definition_is_null() -> void:
		assert_false(_box.can_accept(null))

	func test_returns_true_when_affordable_and_unowned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		assert_true(_box.can_accept(_definition))

	func test_returns_false_when_balance_too_low() -> void:
		assert_false(_box.can_accept(_definition))

	func test_returns_false_when_already_owned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_item_manager.take(_definition.key)
		assert_false(_box.can_accept(_definition))


class TestAccept:
	extends GutTest

	var _box: ClearanceBox
	var _definition: ItemDefinition
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_definition = _item_manager.items[0]
		_box = ClearanceBoxScene.instantiate()
		_box._item_manager = _item_manager
		add_child_autofree(_box)

	func test_accept_marks_item_as_owned() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		_box.accept(_definition)
		assert_eq(_item_manager.get_level(_definition.key), 1)

	func test_accept_deducts_cost_from_balance() -> void:
		_item_manager._progression.friendship_point_balance = 300
		_box.accept(_definition)
		assert_eq(_item_manager.get_friendship_point_balance(), 200)

	func test_accept_emits_item_taken_signal_with_definition() -> void:
		_item_manager._progression.friendship_point_balance = 1000
		watch_signals(_box)
		_box.accept(_definition)
		assert_signal_emitted_with_parameters(_box, "item_taken", [_definition])

	func test_accept_does_not_emit_signal_when_take_fails() -> void:
		watch_signals(_box)
		_box.accept(_definition)
		assert_signal_not_emitted(_box, "item_taken")

	func test_accept_does_not_apply_stat_effects() -> void:
		var base_speed: float = GameRules.base_stats[&"paddle_speed"]
		_item_manager._progression.friendship_point_balance = 1000
		_box.accept(_definition)
		assert_eq(_item_manager.get_stat(&"paddle_speed"), base_speed)


class TestCanDropData:
	extends GutTest

	var _box: ClearanceBox
	var _definition: ItemDefinition
	var _item_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_item_manager._progression.friendship_point_balance = 1000
		_definition = _item_manager.items[0]
		_box = ClearanceBoxScene.instantiate()
		_box._item_manager = _item_manager
		add_child_autofree(_box)

	func test_accepts_item_definition_payload() -> void:
		assert_true(_box._can_drop_data(Vector2.ZERO, _definition))

	func test_rejects_non_item_definition_payload() -> void:
		assert_false(_box._can_drop_data(Vector2.ZERO, "a string"))

	func test_rejects_null_payload() -> void:
		assert_false(_box._can_drop_data(Vector2.ZERO, null))

	func test_rejects_int_payload() -> void:
		assert_false(_box._can_drop_data(Vector2.ZERO, 42))
