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
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.calculate_cost(TEST_KEY), 200)

	func test_can_purchase_false_when_balance_too_low() -> void:
		assert_false(_manager.can_purchase(TEST_KEY))

	func test_can_purchase_true_when_balance_sufficient() -> void:
		_manager.economy.soul_balance = 100
		assert_true(_manager.can_purchase(TEST_KEY))

	func test_can_purchase_false_when_at_max_level() -> void:
		_manager.economy.soul_balance = 10000
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		assert_false(_manager.can_purchase(TEST_KEY))

	func test_purchase_returns_false_when_balance_too_low() -> void:
		assert_false(_manager.purchase(TEST_KEY))

	func test_purchase_returns_true_when_affordable() -> void:
		_manager.economy.soul_balance = 100
		assert_true(_manager.purchase(TEST_KEY))

	func test_purchase_increments_level() -> void:
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 1)

	func test_purchase_deducts_cost_from_balance() -> void:
		_manager.economy.soul_balance = 300
		_manager.purchase(TEST_KEY)
		assert_eq(_manager.get_soul_balance(), 200)

	func test_purchase_returns_false_at_max_level() -> void:
		_manager.economy.soul_balance = 10000
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		_manager.purchase(TEST_KEY)
		assert_false(_manager.purchase(TEST_KEY))

	func test_purchase_emits_item_level_changed() -> void:
		_manager.economy.soul_balance = 1000
		watch_signals(_manager)
		_manager.purchase(TEST_KEY)
		assert_signal_emitted_with_parameters(_manager, "item_level_changed", [TEST_KEY])


class TestDuplicatePricing:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_cost_increases_with_each_purchase() -> void:
		_manager.economy.soul_balance = 10000
		var cost_at_zero: int = _manager.calculate_cost(TEST_KEY)
		_manager.purchase(TEST_KEY)
		var cost_at_one: int = _manager.calculate_cost(TEST_KEY)
		assert_gt(cost_at_one, cost_at_zero)
		_manager.purchase(TEST_KEY)
		var cost_at_two: int = _manager.calculate_cost(TEST_KEY)
		assert_gt(cost_at_two, cost_at_one)


class TestBallRepurchase:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var ball := ItemDefinition.new()
		ball.key = "test_ball"
		ball.base_cost = 100
		ball.cost_scaling = 2.0
		ball.max_level = 5
		ball.effects = []
		_manager.items.assign([ball])

	func test_ball_can_be_purchased_multiple_times() -> void:
		_manager.economy.soul_balance = 10000
		assert_true(_manager.purchase("test_ball"), "first purchase should succeed")
		assert_true(_manager.purchase("test_ball"), "second purchase should succeed")
		assert_eq(_manager.get_level("test_ball"), 2)


class TestStats:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_get_stat_returns_base_value_before_any_purchase() -> void:
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			GameRules.paddle.paddle_speed
		)

	func test_activate_applies_stat_modifier() -> void:
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		_manager.activate(TEST_KEY)
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			GameRules.paddle.paddle_speed + 50.0
		)

	func test_multiple_purchases_stack_modifiers() -> void:
		_manager.economy.soul_balance = 10000
		_manager.purchase(TEST_KEY)
		_manager.activate(TEST_KEY)
		_manager.purchase(TEST_KEY)
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			GameRules.paddle.paddle_speed + 100.0
		)

	func test_remove_level_reverts_stat_modifier() -> void:
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		_manager.activate(TEST_KEY)
		_manager.remove_level(TEST_KEY)
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			GameRules.paddle.paddle_speed
		)


class TestSoul:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_add_soul_increases_balance() -> void:
		_manager.add_soul(50)
		assert_eq(_manager.get_soul_balance(), 50)

	func test_add_soul_emits_signal() -> void:
		watch_signals(_manager)
		_manager.add_soul(50)
		assert_signal_emitted_with_parameters(_manager, "soul_balance_changed", [50])

	func test_subtract_soul_decreases_balance() -> void:
		_manager.economy.soul_balance = 100
		_manager.subtract_soul(30)
		assert_eq(_manager.get_soul_balance(), 70)

	func test_subtract_soul_clamps_to_zero() -> void:
		_manager.economy.soul_balance = 10
		_manager.subtract_soul(50)
		assert_eq(_manager.get_soul_balance(), 0)


class TestRemoveLevel:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_remove_level_decrements_level() -> void:
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		_manager.remove_level(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 0)

	func test_remove_level_does_nothing_at_zero() -> void:
		_manager.remove_level(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 0)

	func test_remove_level_emits_item_level_changed() -> void:
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		watch_signals(_manager)
		_manager.remove_level(TEST_KEY)
		assert_signal_emitted_with_parameters(_manager, "item_level_changed", [TEST_KEY])

	func test_remove_level_refunds_soul() -> void:
		_manager.economy.soul_balance = 1000
		var balance_before_purchase: int = _manager.economy.soul_balance
		_manager.purchase(TEST_KEY)
		var cost_paid: int = balance_before_purchase - _manager.economy.soul_balance
		_manager.remove_level(TEST_KEY)
		assert_eq(
			_manager.economy.soul_balance,
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
		_manager.economy.soul_balance = 100
		assert_true(_manager.can_acquire(TEST_KEY))


class TestTake:
	extends GutTest
	const TEST_KEY := "test_ball"
	const TEST_INSTANCE_KEY := "test_ball_1"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var ball := ItemDefinition.new()
		ball.key = TEST_KEY
		ball.base_cost = 100
		ball.cost_scaling = 2.0
		ball.max_level = 3
		ball.effects = []
		_manager.items.assign([ball] as Array[ItemDefinition])

	func test_take_returns_empty_string_when_balance_too_low() -> void:
		assert_eq(_manager.take(TEST_KEY), "")

	func test_take_returns_instance_key_when_affordable() -> void:
		_manager.economy.soul_balance = 100
		assert_eq(_manager.take(TEST_KEY), TEST_INSTANCE_KEY)

	func test_take_marks_instance_as_owned() -> void:
		_manager.economy.soul_balance = 100
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_level(TEST_INSTANCE_KEY), 1)

	func test_take_deducts_cost_from_balance() -> void:
		_manager.economy.soul_balance = 300
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_soul_balance(), 200)

	func test_take_emits_item_manager_state_changed() -> void:
		_manager.economy.soul_balance = 100
		watch_signals(_manager)
		_manager.take(TEST_KEY)
		assert_signal_emitted(_manager, "item_manager_state_changed")

	func test_take_emits_soul_balance_changed() -> void:
		_manager.economy.soul_balance = 100
		watch_signals(_manager)
		_manager.take(TEST_KEY)
		assert_signal_emitted(_manager, "soul_balance_changed")

	func test_take_does_not_apply_stat_effects() -> void:
		var base_value: float = GameRules.base.ball_speed_min
		_manager.economy.soul_balance = 100
		_manager.take(TEST_KEY)
		assert_eq(
			Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager),
			base_value,
			"take should not register the item's effects",
		)


class TestReloadFromProgression:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)

	func test_reload_reregisters_effects_from_current_levels() -> void:
		var base_speed: float = GameRules.paddle.paddle_speed
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			base_speed,
			"no level, no effect"
		)
		# Simulate progression data being rewritten externally (e.g. dev clear-save)
		ItemFactory.give(_manager, TEST_KEY)
		_manager.state.item_placements[TEST_KEY] = Placement.ON_COURT
		_manager.reload_from_progression()
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			base_speed + 50.0,
			"reload should re-register effects matching the restored level"
		)

	func test_reload_unregisters_previously_registered_effects_when_level_is_zero() -> void:
		var base_speed: float = GameRules.paddle.paddle_speed
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		_manager.activate(TEST_KEY)
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			base_speed + 50.0
		)
		# Simulate progression data being rewritten externally
		_manager.state.item_levels.clear()
		_manager.reload_from_progression()
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			base_speed,
			"reload should drop effects that no longer have a level"
		)


class TestStoredItems:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var ball_item := ItemDefinition.new()
		ball_item.key = "stored_ball"
		ball_item.base_cost = 100
		ball_item.cost_scaling = 2.0
		ball_item.max_level = 3
		ball_item.effects = []
		_manager.items.assign([ball_item])
		_manager.economy.soul_balance = 10000

	func test_get_stored_items_is_empty_when_nothing_owned() -> void:
		assert_eq(_manager.get_stored_items().size(), 0)

	func test_get_stored_items_returns_owned_stored_items() -> void:
		_manager.take("stored_ball")
		var stored: Array[String] = _manager.get_stored_items()
		assert_eq(stored.size(), 1)
		assert_eq(stored[0], "stored_ball_1")

	func test_get_stored_items_excludes_unowned_items() -> void:
		assert_eq(_manager.get_level("stored_ball"), 0)
		assert_eq(_manager.get_stored_items().size(), 0)

	func test_get_stored_items_excludes_activated_items() -> void:
		_manager.take("stored_ball")
		_manager.activate("stored_ball_1")
		assert_eq(_manager.get_stored_items().size(), 0)

	func test_get_stored_items_includes_items_after_deactivation() -> void:
		_manager.take("stored_ball")
		_manager.activate("stored_ball_1")
		_manager.deactivate("stored_ball_1")
		var stored: Array[String] = _manager.get_stored_items()
		assert_eq(stored.size(), 1)
		assert_eq(stored[0], "stored_ball_1")


class TestRackSlotAssignment:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var typed: Array[ItemDefinition] = []
		for key: String in ["ball_one", "ball_two"]:
			var ball_item := ItemDefinition.new()
			ball_item.key = key
			ball_item.base_cost = 100
			ball_item.cost_scaling = 2.0
			ball_item.max_level = 3
			ball_item.effects = []
			typed.append(ball_item)
		_manager.items.assign(typed)

	func test_first_stored_ball_takes_slot_zero() -> void:
		ItemFactory.give(_manager, "ball_one")
		assert_eq(_manager.get_rack_slot_index("ball_one"), 0)

	func test_release_frees_the_slot() -> void:
		ItemFactory.give(_manager, "ball_one")
		_manager.release_rack_slot("ball_one")
		assert_eq(
			_manager.get_rack_slot_index("ball_one"),
			-1,
			"a held ball must vacate its slot so a concurrent insert can take slot 0",
		)

	func test_concurrent_insert_fills_slot_zero_while_a_ball_is_held() -> void:
		ItemFactory.give(_manager, "ball_one")
		_manager.release_rack_slot("ball_one")

		ItemFactory.give(_manager, "ball_two")

		assert_eq(
			_manager.get_rack_slot_index("ball_two"),
			0,
			"with the held ball's slot freed, the new entry must fill slot 0, not slot 1",
		)

	func test_restore_reclaims_the_next_free_slot() -> void:
		ItemFactory.give(_manager, "ball_one")
		_manager.release_rack_slot("ball_one")
		ItemFactory.give(_manager, "ball_two")

		_manager.reassign_rack_slot("ball_one")

		assert_eq(
			_manager.get_rack_slot_index("ball_one"),
			1,
			"the restored ball reclaims the lowest free slot, slot 1",
		)


class TestItemManagerStateChanged:
	extends GutTest
	const TEST_KEY := "test_speed"
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		_manager.economy.soul_balance = 1000
		_manager.purchase(TEST_KEY)
		watch_signals(_manager)

	func test_non_stored_clears_loose_in_venue() -> void:
		_manager.mark_loose_in_venue(TEST_KEY)
		assert_true(_manager.is_loose_in_venue(TEST_KEY), "precondition: item is loose")
		_manager.activate(TEST_KEY)
		assert_false(
			_manager.is_loose_in_venue(TEST_KEY),
			"activate should clear loose_in_venue from non-STORED branch",
		)
