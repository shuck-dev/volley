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
		ball.role = &"ball"
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

	func test_ball_take_blocks_re_purchase() -> void:
		_manager.economy.soul_balance = 10000
		assert_true(_manager.take("test_ball"), "first take should succeed")
		assert_false(_manager.take("test_ball"), "take must block re-purchase for ball items too")


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
		_manager.take(TEST_KEY)
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

	func test_returns_false_when_already_owned() -> void:
		_manager.economy.soul_balance = 1000
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
		_manager.economy.soul_balance = 100
		assert_true(_manager.take(TEST_KEY))

	func test_take_marks_item_as_owned() -> void:
		_manager.economy.soul_balance = 100
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_level(TEST_KEY), 1)

	func test_take_deducts_cost_from_balance() -> void:
		_manager.economy.soul_balance = 300
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_soul_balance(), 200)

	func test_take_returns_false_when_already_owned() -> void:
		_manager.economy.soul_balance = 1000
		_manager.take(TEST_KEY)
		assert_false(_manager.take(TEST_KEY))

	func test_take_does_not_deduct_cost_when_already_owned() -> void:
		_manager.economy.soul_balance = 1000
		_manager.take(TEST_KEY)
		var balance_after_first_take: int = _manager.get_soul_balance()
		_manager.take(TEST_KEY)
		assert_eq(_manager.get_soul_balance(), balance_after_first_take)

	func test_take_emits_item_level_changed() -> void:
		_manager.economy.soul_balance = 100
		watch_signals(_manager)
		_manager.take(TEST_KEY)
		assert_signal_emitted_with_parameters(_manager, "item_level_changed", [TEST_KEY])

	func test_take_emits_soul_balance_changed() -> void:
		_manager.economy.soul_balance = 100
		watch_signals(_manager)
		_manager.take(TEST_KEY)
		assert_signal_emitted(_manager, "soul_balance_changed")

	func test_take_does_not_apply_stat_effects() -> void:
		var base_speed: float = GameRules.paddle.paddle_speed
		_manager.economy.soul_balance = 100
		_manager.take(TEST_KEY)
		assert_eq(
			Stats.resolve(GameRules.paddle.paddle_speed, &"paddle_speed", _manager),
			base_speed,
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
		_manager.state.item_placements[TEST_KEY] = Placement.EQUIPPED
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


class TestKitItemsBall:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var ball_item := ItemDefinition.new()
		ball_item.key = "kit_ball"
		ball_item.role = &"ball"
		ball_item.base_cost = 100
		ball_item.cost_scaling = 2.0
		ball_item.max_level = 3
		ball_item.effects = []
		_manager.items.assign([ball_item])
		_manager.economy.soul_balance = 10000

	func test_get_kit_items_is_empty_when_nothing_owned() -> void:
		assert_eq(_manager.get_kit_items(&"ball").size(), 0)

	func test_get_kit_items_returns_owned_stored_ball_items() -> void:
		_manager.take("kit_ball")
		var ball_kit: Array[String] = _manager.get_kit_items(&"ball")
		assert_eq(ball_kit.size(), 1)
		assert_eq(ball_kit[0], "kit_ball")

	func test_get_kit_items_excludes_ball_when_queried_for_equipment_role() -> void:
		_manager.take("kit_ball")
		assert_eq(_manager.get_kit_items(&"equipment").size(), 0)

	func test_get_kit_items_excludes_unowned_ball_items() -> void:
		assert_eq(_manager.get_level("kit_ball"), 0)
		assert_eq(_manager.get_kit_items(&"ball").size(), 0)

	func test_get_kit_items_excludes_activated_ball_items() -> void:
		_manager.take("kit_ball")
		_manager.activate("kit_ball")
		assert_eq(_manager.get_kit_items(&"ball").size(), 0)

	func test_get_kit_items_includes_ball_items_after_deactivation() -> void:
		_manager.take("kit_ball")
		_manager.activate("kit_ball")
		_manager.deactivate("kit_ball")
		var kit: Array[String] = _manager.get_kit_items(&"ball")
		assert_eq(kit.size(), 1)
		assert_eq(kit[0], "kit_ball")


class TestRackSlotAssignment:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var typed: Array[ItemDefinition] = []
		for key: String in ["ball_one", "ball_two"]:
			var ball_item := ItemDefinition.new()
			ball_item.key = key
			ball_item.role = &"ball"
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


class TestKitItemsEquipment:
	extends GutTest
	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var gear_item := ItemDefinition.new()
		gear_item.key = "kit_gear"
		gear_item.role = &"equipment"
		gear_item.base_cost = 100
		gear_item.cost_scaling = 2.0
		gear_item.max_level = 3
		gear_item.effects = []
		_manager.items.assign([gear_item])
		_manager.economy.soul_balance = 10000

	func test_get_kit_items_is_empty_when_nothing_owned() -> void:
		assert_eq(_manager.get_kit_items(&"equipment").size(), 0)

	func test_get_kit_items_returns_owned_stored_equipment_items() -> void:
		_manager.take("kit_gear")
		var gear_kit: Array[String] = _manager.get_kit_items(&"equipment")
		assert_eq(gear_kit.size(), 1)
		assert_eq(gear_kit[0], "kit_gear")

	func test_get_kit_items_excludes_equipment_when_queried_for_ball_role() -> void:
		_manager.take("kit_gear")
		assert_eq(_manager.get_kit_items(&"ball").size(), 0)

	func test_get_kit_items_excludes_unowned_equipment_items() -> void:
		assert_eq(_manager.get_level("kit_gear"), 0)
		assert_eq(_manager.get_kit_items(&"equipment").size(), 0)

	func test_get_kit_items_excludes_activated_equipment_items() -> void:
		_manager.take("kit_gear")
		_manager.activate("kit_gear")
		assert_eq(_manager.get_kit_items(&"equipment").size(), 0)

	func test_get_kit_items_includes_equipment_items_after_deactivation() -> void:
		_manager.take("kit_gear")
		_manager.activate("kit_gear")
		_manager.deactivate("kit_gear")
		var kit: Array[String] = _manager.get_kit_items(&"equipment")
		assert_eq(kit.size(), 1)
		assert_eq(kit[0], "kit_gear")


class TestEquipFlow:
	extends GutTest

	## Equip/unequip/get_kit_remaining gate equipment placement on the kit_slots cap.

	var _manager: Node

	func before_each() -> void:
		_manager = ItemFactory.create_manager(self)
		var gear_a := ItemDefinition.new()
		gear_a.key = "gear_a"
		gear_a.role = &"equipment"
		gear_a.base_cost = 10
		gear_a.cost_scaling = 2.0
		gear_a.max_level = 3
		gear_a.effects = []
		var gear_b := ItemDefinition.new()
		gear_b.key = "gear_b"
		gear_b.role = &"equipment"
		gear_b.base_cost = 10
		gear_b.cost_scaling = 2.0
		gear_b.max_level = 3
		gear_b.effects = []
		var ball := ItemDefinition.new()
		ball.key = "ball_a"
		ball.role = &"ball"
		ball.base_cost = 10
		ball.cost_scaling = 2.0
		ball.max_level = 3
		ball.effects = []
		_manager.items.assign([gear_a, gear_b, ball])
		_manager.economy.soul_balance = 100000

	func test_get_kit_remaining_starts_at_floored_kit_slots() -> void:
		var expected: int = int(floor(GameRules.base.kit_slots))
		assert_eq(_manager.get_kit_remaining(), expected)

	func test_equip_reduces_kit_remaining() -> void:
		_manager.take("gear_a")
		var before: int = _manager.get_kit_remaining()
		assert_true(_manager.equip("gear_a"))
		assert_eq(_manager.get_kit_remaining(), before - 1)

	func test_unequip_restores_kit_remaining() -> void:
		_manager.take("gear_a")
		var before: int = _manager.get_kit_remaining()
		_manager.equip("gear_a")
		assert_true(_manager.unequip("gear_a"))
		assert_eq(_manager.get_kit_remaining(), before)

	func test_loose_in_venue_overlay_does_not_affect_kit_remaining() -> void:
		# Ball-role overlay must not change the equipment-kit count.
		_manager.take("ball_a")
		var before: int = _manager.get_kit_remaining()
		_manager.mark_loose_in_venue("ball_a")
		assert_eq(_manager.get_kit_remaining(), before)

	func test_equip_rejects_ball_role_silently() -> void:
		_manager.take("ball_a")
		watch_signals(_manager)
		assert_false(_manager.equip("ball_a"))
		assert_signal_not_emitted(_manager, "equip_refused")

	func test_equip_rejects_when_capacity_zero_and_emits_refused() -> void:
		# Force capacity to zero by stuffing the persisted-EQUIPPED set up to the cap.
		var cap: int = int(floor(GameRules.base.kit_slots))
		var pad_items: Array[ItemDefinition] = []
		for i in cap:
			var pad := ItemDefinition.new()
			pad.key = "pad_%d" % i
			pad.role = &"equipment"
			pad.base_cost = 10
			pad.cost_scaling = 2.0
			pad.max_level = 3
			pad.effects = []
			pad_items.append(pad)
		for pad: ItemDefinition in pad_items:
			_manager.items.append(pad)
			_manager.take(pad.key)
			_manager.equip(pad.key)
		assert_eq(_manager.get_kit_remaining(), 0, "precondition: cap reached")

		_manager.take("gear_a")
		watch_signals(_manager)
		assert_false(_manager.equip("gear_a"))
		assert_signal_emitted_with_parameters(
			_manager, "equip_refused", ["gear_a", &"capacity_exceeded"]
		)

	func test_over_capacity_load_clamps_kit_remaining_to_zero() -> void:
		# Simulate a save with more EQUIPPED items than the current cap supports.
		var cap: int = int(floor(GameRules.base.kit_slots))
		for i in cap + 2:
			_manager.state.item_placements["over_%d" % i] = Placement.EQUIPPED
		assert_eq(_manager.get_kit_remaining(), 0)

	func test_unequip_on_unowned_returns_false() -> void:
		assert_false(_manager.unequip("gear_a"))


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
