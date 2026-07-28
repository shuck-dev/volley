extends GutTest


class TestShopUnlock:
	extends GutTest
	var _ball_manager: Node
	var _progression_manager: Node
	var _threshold: int

	func before_each() -> void:
		_ball_manager = BallFactory.create_manager(self)
		_progression_manager = ProgressionManagerFactory.create_manager(self, _ball_manager)
		_threshold = _progression_manager._config.shop_unlock_threshold

	func test_shop_unlocked_by_default() -> void:
		assert_true(_progression_manager.is_shop_unlocked())

	func test_shop_stays_unlocked_below_threshold() -> void:
		_ball_manager.add_soul(_threshold - 1)
		assert_true(_progression_manager.is_shop_unlocked())

	func test_shop_signal_not_emitted_below_threshold() -> void:
		watch_signals(_progression_manager)
		_ball_manager.add_soul(_threshold - 1)
		assert_signal_not_emitted(_progression_manager, "shop_unlocked_changed")

	func test_shop_stays_unlocked_when_balance_drops() -> void:
		_ball_manager.add_soul(_threshold + 100)
		_ball_manager.subtract_soul(_threshold + 50)
		assert_true(_progression_manager.is_shop_unlocked())

	func test_shop_signal_not_emitted_twice() -> void:
		_ball_manager.add_soul(_threshold)
		watch_signals(_progression_manager)
		_ball_manager.add_soul(10)
		assert_signal_not_emitted(_progression_manager, "shop_unlocked_changed")

	func test_shop_reunlocks_after_save_cleared() -> void:
		_progression_manager.unlocks.shop_unlocked = false
		watch_signals(_progression_manager)

		_progression_manager._save_manager.save_cleared.emit()

		assert_true(_progression_manager.is_shop_unlocked())
		assert_signal_emitted_with_parameters(_progression_manager, "shop_unlocked_changed", [true])

	func test_spending_does_not_reduce_total_earned() -> void:
		_ball_manager.add_soul(100)
		_ball_manager.subtract_soul(100)
		assert_eq(_ball_manager.economy.total_soul_earned, 100)

	func test_refund_does_not_count_as_earning() -> void:
		_ball_manager.add_soul(200)
		var total_before: int = _ball_manager.economy.total_soul_earned
		_ball_manager._refund_soul(50)
		assert_eq(
			_ball_manager.economy.total_soul_earned,
			total_before,
			"refunds must not inflate the cumulative earned counter"
		)
		assert_eq(_ball_manager.economy.soul_balance, 250, "balance should refund")


class TestShopPersistence:
	extends GutTest

	func test_shop_unlocked_defaults_to_false_from_empty_dict() -> void:
		var unlocks := UnlocksState.new()
		unlocks.apply_save_dict({})
		assert_false(unlocks.shop_unlocked)

	func test_shop_unlocked_round_trips_through_dict() -> void:
		var unlocks := UnlocksState.new()
		unlocks.apply_save_dict({"shop_unlocked": true})
		var restored := UnlocksState.new()
		restored.apply_save_dict(unlocks.to_save_dict())
		assert_true(restored.shop_unlocked)

	func test_shop_unlock_persists_in_progression_data() -> void:
		var ball_manager: Node = BallFactory.create_manager(self)
		var progression_manager: Node = ProgressionManagerFactory.create_manager(self, ball_manager)
		ball_manager.add_soul(progression_manager._config.shop_unlock_threshold)
		assert_true(progression_manager.unlocks.shop_unlocked)
