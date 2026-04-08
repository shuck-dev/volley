extends GutTest


class TestShopUnlock:
	extends GutTest
	var _item_manager: Node
	var _progression_manager: Node
	var _threshold: int

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_progression_manager = ProgressionManagerFactory.create_manager(self, _item_manager)
		_threshold = _progression_manager._config.shop_unlock_threshold

	func test_shop_not_unlocked_by_default() -> void:
		assert_false(_progression_manager.is_shop_unlocked())

	func test_shop_unlocks_when_friendship_reaches_threshold() -> void:
		_item_manager.add_friendship_points(_threshold)
		assert_true(_progression_manager.is_shop_unlocked())

	func test_shop_does_not_unlock_below_threshold() -> void:
		_item_manager.add_friendship_points(_threshold - 1)
		assert_false(_progression_manager.is_shop_unlocked())

	func test_shop_unlocked_signal_emitted_on_unlock() -> void:
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(_threshold)
		assert_signal_emitted_with_parameters(_progression_manager, "shop_unlocked_changed", [true])

	func test_shop_signal_not_emitted_below_threshold() -> void:
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(_threshold - 1)
		assert_signal_not_emitted(_progression_manager, "shop_unlocked_changed")

	func test_shop_stays_unlocked_when_balance_drops() -> void:
		_item_manager.add_friendship_points(_threshold + 100)
		_item_manager.subtract_friendship_points(_threshold + 50)
		assert_true(_progression_manager.is_shop_unlocked())

	func test_shop_signal_not_emitted_twice() -> void:
		_item_manager.add_friendship_points(_threshold)
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(10)
		assert_signal_not_emitted(_progression_manager, "shop_unlocked_changed")

	func test_shop_unlocks_when_total_earned_reaches_threshold_even_after_spending() -> void:
		_item_manager.add_friendship_points(_threshold - 10)
		_item_manager.subtract_friendship_points(_threshold - 20)
		assert_false(_progression_manager.is_shop_unlocked(), "not yet at threshold total")
		_item_manager.add_friendship_points(15)
		assert_true(
			_progression_manager.is_shop_unlocked(),
			"cumulative earnings crossed threshold after spending"
		)

	func test_spending_does_not_reduce_total_earned() -> void:
		_item_manager.add_friendship_points(100)
		_item_manager.subtract_friendship_points(100)
		assert_eq(_item_manager._progression.total_friendship_points_earned, 100)

	func test_refund_does_not_count_as_earning() -> void:
		_item_manager.add_friendship_points(200)
		var total_before: int = _item_manager._progression.total_friendship_points_earned
		_item_manager._refund_friendship_points(50)
		assert_eq(
			_item_manager._progression.total_friendship_points_earned,
			total_before,
			"refunds must not inflate the cumulative earned counter"
		)
		assert_eq(_item_manager._progression.friendship_point_balance, 250, "balance should refund")


class TestShopPersistence:
	extends GutTest

	func test_shop_unlocked_defaults_to_false_from_empty_dict() -> void:
		var progression := ProgressionData.from_dict({})
		assert_false(progression.shop_unlocked)

	func test_shop_unlocked_round_trips_through_dict() -> void:
		var progression := ProgressionData.from_dict({"shop_unlocked": true})
		var restored := ProgressionData.from_dict(progression.to_dict())
		assert_true(restored.shop_unlocked)

	func test_shop_unlock_persists_in_progression_data() -> void:
		var item_manager: Node = ItemFactory.create_manager(self)
		var progression_manager: Node = ProgressionManagerFactory.create_manager(self, item_manager)
		item_manager.add_friendship_points(progression_manager._config.shop_unlock_threshold)
		assert_true(item_manager._progression.shop_unlocked)

	func test_deferred_unlock_signal_emitted_for_preunlocked_save() -> void:
		var item_manager: Node = ItemFactory.create_manager(self)
		item_manager._progression.shop_unlocked = true
		var progression_manager: Node = ProgressionManagerFactory.create_manager(self, item_manager)
		watch_signals(progression_manager)
		await get_tree().process_frame
		assert_signal_emitted_with_parameters(progression_manager, "shop_unlocked_changed", [true])
