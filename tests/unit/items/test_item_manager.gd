extends GutTest


class TestPurchase:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_get_level_returns_zero_before_any_purchase() -> void:
		assert_eq(_manager.get_level(TEST_KEY), 0)

	func test_calculate_cost_returns_base_cost_at_level_zero() -> void:
		assert_eq(_manager.calculate_cost(TEST_KEY), 100)

	func test_calculate_cost_scales_after_first_purchase() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.calculate_cost(TEST_KEY), 200)

	func test_can_purchase_false_when_balance_too_low() -> void:
		assert_false(_manager.can_purchase(TEST_KEY))

	func test_can_purchase_true_when_balance_sufficient() -> void:
		_manager._progression.friendship_point_balance = 100
		assert_true(_manager.can_purchase(TEST_KEY))

	func test_can_purchase_false_when_at_max_level() -> void:
		_manager._progression.friendship_point_balance = 10000
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		assert_false(_manager.can_purchase(TEST_KEY))

	func test_purchase_returns_false_when_balance_too_low() -> void:
		assert_false(_manager.purchase(TEST_KEY))

	func test_purchase_returns_true_when_affordable() -> void:
		_manager._progression.friendship_point_balance = 100
		assert_true(_manager.purchase(TEST_KEY))

	func test_purchase_increments_level() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 1)

	func test_purchase_deducts_cost_from_balance() -> void:
		_manager._progression.friendship_point_balance = 300
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_friendship_point_balance(), 200)

	func test_purchase_returns_false_at_max_level() -> void:
		_manager._progression.friendship_point_balance = 10000
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		assert_false(_manager.purchase(TEST_KEY))

	func test_purchase_emits_item_level_changed() -> void:
		_manager._progression.friendship_point_balance = 1000
		watch_signals(_manager)
		_manager.purchase(TEST_KEY)
		assert_signal_emitted_with_parameters(_manager, "item_level_changed", [TEST_KEY])


class TestStats:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_get_stat_returns_base_value_before_any_purchase() -> void:
		assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"])

	func test_purchase_applies_stat_modifier() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] + 50.0)

	func test_multiple_purchases_stack_modifiers() -> void:
		_manager._progression.friendship_point_balance = 10000
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] + 100.0)

	func test_remove_level_reverts_stat_modifier() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		_manager.remove_level(TEST_KEY)
		assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"])


class TestFriendshipPoints:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_add_friendship_points_increases_balance() -> void:
		_manager.add_friendship_points(50)
		assert_eq(_manager.get_friendship_point_balance(), 50)

	func test_add_friendship_points_emits_signal() -> void:
		watch_signals(_manager)
		_manager.add_friendship_points(50)
		assert_signal_emitted_with_parameters(_manager, "friendship_point_balance_changed", [50])

	func test_subtract_friendship_points_decreases_balance() -> void:
		_manager._progression.friendship_point_balance = 100
		_manager.subtract_friendship_points(30)
		assert_eq(_manager.get_friendship_point_balance(), 70)

	func test_subtract_friendship_points_clamps_to_zero() -> void:
		_manager._progression.friendship_point_balance = 10
		_manager.subtract_friendship_points(50)
		assert_eq(_manager.get_friendship_point_balance(), 0)


class TestRemoveLevel:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_remove_level_decrements_level() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		_manager.remove_level(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 0)

	func test_remove_level_does_nothing_at_zero() -> void:
		_manager.remove_level(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 0)

	func test_remove_level_emits_item_level_changed() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		watch_signals(_manager)
		_manager.remove_level(TEST_KEY)
		assert_signal_emitted_with_parameters(_manager, "item_level_changed", [TEST_KEY])

	func test_remove_level_refunds_friendship_points() -> void:
		_manager._progression.friendship_point_balance = 1000
		var balance_before_purchase: int = _manager._progression.friendship_point_balance
		_manager.purchase(TEST_KEY)
		var cost_paid: int = (
			balance_before_purchase - _manager._progression.friendship_point_balance
		)
		_manager.remove_level(TEST_KEY)
		assert_eq(
			_manager._progression.friendship_point_balance,
			balance_before_purchase,
			"removing a level should refund the cost paid",
		)


class TestCanAcquire:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_returns_false_when_balance_too_low() -> void:
		assert_false(_manager.can_acquire(TEST_KEY))

	func test_returns_true_when_affordable_and_unowned() -> void:
		_manager._progression.friendship_point_balance = 100
		assert_true(_manager.can_acquire(TEST_KEY))

	func test_returns_false_when_already_owned() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.take(TEST_KEY)
		assert_false(_manager.can_acquire(TEST_KEY))


class TestTake:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_take_returns_false_when_balance_too_low() -> void:
		assert_false(_manager.take(TEST_KEY))

	func test_take_returns_true_when_affordable() -> void:
		_manager._progression.friendship_point_balance = 100
		assert_true(_manager.take(TEST_KEY))

	func test_take_marks_item_as_owned() -> void:
		_manager._progression.friendship_point_balance = 100
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 1)

	func test_take_deducts_cost_from_balance() -> void:
		_manager._progression.friendship_point_balance = 300
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_friendship_point_balance(), 200)

	func test_take_returns_false_when_already_owned() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.take(TEST_KEY)
		assert_false(_manager.take(TEST_KEY))

	func test_take_does_not_deduct_cost_when_already_owned() -> void:
		_manager._progression.friendship_point_balance = 1000
		_manager.take(TEST_KEY)
		var balance_after_first_take: int = _manager.get_friendship_point_balance()
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_friendship_point_balance(), balance_after_first_take)

	func test_take_emits_item_level_changed() -> void:
		_manager._progression.friendship_point_balance = 100
		watch_signals(_manager)
		_manager.take(TEST_KEY)
		assert_signal_emitted_with_parameters(_manager, "item_level_changed", [TEST_KEY])

	func test_take_emits_friendship_point_balance_changed() -> void:
		_manager._progression.friendship_point_balance = 100
		watch_signals(_manager)
		_manager.take(TEST_KEY)
		assert_signal_emitted(_manager, "friendship_point_balance_changed")

	func test_take_does_not_apply_stat_effects() -> void:
		var base_speed: float = GameRules.base_stats[&"paddle_speed"]
		_manager._progression.friendship_point_balance = 100
		_manager.take(TEST_KEY)
		assert_eq(
			_manager.get_stat(&"paddle_speed"),
			base_speed,
			"take should not register the item's effects",
		)


class TestReloadFromProgression:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_reload_emits_friendship_balance_changed() -> void:
		watch_signals(_manager)
		_manager.reload_from_progression()
		assert_signal_emitted(_manager, "friendship_point_balance_changed")

	func test_reload_emits_item_level_changed_for_each_item() -> void:
		watch_signals(_manager)
		_manager.reload_from_progression()
		assert_signal_emit_count(_manager, "item_level_changed", _manager.items.size())

	func test_reload_reregisters_effects_from_current_levels() -> void:
		var base_speed: float = GameRules.base_stats[&"paddle_speed"]
		assert_eq(_manager.get_stat(&"paddle_speed"), base_speed, "no level, no effect")
		# Simulate progression data being rewritten externally (e.g. dev clear-save)
		_manager._progression.item_levels[TEST_KEY] = 1
		_manager._progression.item_placements[TEST_KEY] = (
			preload("res://scripts/items/placement.gd").EQUIPPED
		)
		_manager.reload_from_progression()
		assert_eq(
			_manager.get_stat(&"paddle_speed"),
			base_speed + 50.0,
			"reload should re-register effects matching the restored level"
		)

	func test_reload_unregisters_previously_registered_effects_when_level_is_zero() -> void:
		var base_speed: float = GameRules.base_stats[&"paddle_speed"]
		_manager._progression.friendship_point_balance = 1000
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_stat(&"paddle_speed"), base_speed + 50.0)
		# Simulate progression data being rewritten externally
		_manager._progression.item_levels.clear()
		_manager.reload_from_progression()
		assert_eq(
			_manager.get_stat(&"paddle_speed"),
			base_speed,
			"reload should drop effects that no longer have a level"
		)
