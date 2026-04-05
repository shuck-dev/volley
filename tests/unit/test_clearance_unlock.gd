extends GutTest


class TestClearanceUnlock:
	extends GutTest
	var _item_manager: Node
	var _progression_manager: Node

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_progression_manager = ProgressionManagerFactory.create_manager(self, _item_manager)

	func test_clearance_not_unlocked_by_default() -> void:
		assert_false(_progression_manager.is_clearance_unlocked())

	func test_clearance_unlocks_when_friendship_reaches_threshold() -> void:
		_item_manager.add_friendship_points(_progression_manager.CLEARANCE_UNLOCK_THRESHOLD)
		assert_true(_progression_manager.is_clearance_unlocked())

	func test_clearance_does_not_unlock_below_threshold() -> void:
		_item_manager.add_friendship_points(_progression_manager.CLEARANCE_UNLOCK_THRESHOLD - 1)
		assert_false(_progression_manager.is_clearance_unlocked())

	func test_clearance_unlocked_signal_emitted_on_unlock() -> void:
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(_progression_manager.CLEARANCE_UNLOCK_THRESHOLD)
		assert_signal_emitted_with_parameters(
			_progression_manager, "clearance_unlocked_changed", [true]
		)

	func test_clearance_signal_not_emitted_below_threshold() -> void:
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(_progression_manager.CLEARANCE_UNLOCK_THRESHOLD - 1)
		assert_signal_not_emitted(_progression_manager, "clearance_unlocked_changed")

	func test_clearance_stays_unlocked_when_balance_drops() -> void:
		_item_manager.add_friendship_points(_progression_manager.CLEARANCE_UNLOCK_THRESHOLD + 100)
		_item_manager.subtract_friendship_points(
			_progression_manager.CLEARANCE_UNLOCK_THRESHOLD + 50
		)
		assert_true(_progression_manager.is_clearance_unlocked())

	func test_clearance_signal_not_emitted_twice() -> void:
		_item_manager.add_friendship_points(_progression_manager.CLEARANCE_UNLOCK_THRESHOLD)
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(10)
		assert_signal_not_emitted(_progression_manager, "clearance_unlocked_changed")


class TestClearancePersistence:
	extends GutTest

	func test_clearance_unlocked_defaults_to_false_from_empty_dict() -> void:
		var progression := ProgressionData.from_dict({})
		assert_false(progression.clearance_unlocked)

	func test_clearance_unlocked_round_trips_through_dict() -> void:
		var progression := ProgressionData.from_dict({"clearance_unlocked": true})
		var restored := ProgressionData.from_dict(progression.to_dict())
		assert_true(restored.clearance_unlocked)

	func test_clearance_unlock_persists_in_progression_data() -> void:
		var item_manager: Node = ItemFactory.create_manager(self)
		var progression_manager: Node = ProgressionManagerFactory.create_manager(self, item_manager)
		item_manager.add_friendship_points(progression_manager.CLEARANCE_UNLOCK_THRESHOLD)
		assert_true(item_manager._progression.clearance_unlocked)
