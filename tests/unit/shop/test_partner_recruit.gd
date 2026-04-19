extends GutTest


class TestPartnerRecruit:
	extends GutTest
	var _item_manager: Node
	var _progression_manager: Node
	var _martha: PartnerDefinition

	func before_each() -> void:
		_item_manager = ItemFactory.create_manager(self)
		_progression_manager = ProgressionManagerFactory.create_manager(self, _item_manager)
		_martha = _progression_manager.partners[0]

	func test_partner_not_unlocked_by_default() -> void:
		assert_false(_progression_manager.is_partner_unlocked(&"martha"))

	func test_cannot_recruit_below_threshold() -> void:
		_item_manager.add_friendship_points(_martha.unlock_threshold - 1)
		assert_false(_progression_manager.can_recruit_partner(&"martha"))

	func test_cannot_recruit_without_enough_balance() -> void:
		_item_manager.add_friendship_points(_martha.unlock_threshold)
		_item_manager.subtract_friendship_points(_martha.unlock_threshold - _martha.unlock_cost + 1)
		assert_false(_progression_manager.can_recruit_partner(&"martha"))

	func test_can_recruit_at_threshold_with_balance() -> void:
		_item_manager.add_friendship_points(_martha.unlock_threshold)
		assert_true(_progression_manager.can_recruit_partner(&"martha"))

	func test_recruit_deducts_cost() -> void:
		_item_manager.add_friendship_points(_martha.unlock_cost + 50)
		_progression_manager.recruit_partner(&"martha")
		assert_eq(_item_manager.get_friendship_point_balance(), 50)

	func test_recruit_sets_active_partner() -> void:
		_item_manager.add_friendship_points(_martha.unlock_cost)
		_progression_manager.recruit_partner(&"martha")
		assert_eq(_item_manager._progression.active_partner, &"martha")

	func test_recruit_adds_to_unlocked_partners() -> void:
		_item_manager.add_friendship_points(_martha.unlock_cost)
		_progression_manager.recruit_partner(&"martha")
		assert_true(&"martha" in _item_manager._progression.unlocked_partners)

	func test_recruit_emits_partner_recruited() -> void:
		_item_manager.add_friendship_points(_martha.unlock_cost)
		watch_signals(_progression_manager)
		_progression_manager.recruit_partner(&"martha")
		assert_signal_emitted_with_parameters(
			_progression_manager, "partner_recruited", [&"martha"]
		)

	func test_recruit_returns_false_when_already_unlocked() -> void:
		_item_manager.add_friendship_points(_martha.unlock_cost * 2)
		_progression_manager.recruit_partner(&"martha")
		assert_false(_progression_manager.recruit_partner(&"martha"))

	func test_recruit_returns_false_for_unknown_partner() -> void:
		assert_false(_progression_manager.recruit_partner(&"unknown"))

	func test_recruit_available_signal_emitted_at_threshold() -> void:
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(_martha.unlock_threshold)
		assert_signal_emitted(_progression_manager, "partner_recruit_available")

	func test_recruit_available_not_emitted_below_threshold() -> void:
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(_martha.unlock_threshold - 1)
		assert_signal_not_emitted(_progression_manager, "partner_recruit_available")

	func test_threshold_persists_recruit_offered() -> void:
		_item_manager.add_friendship_points(_martha.unlock_threshold)
		assert_true(&"martha" in _item_manager._progression.recruit_offered_partners)

	func test_recruit_available_not_emitted_after_recruited() -> void:
		_item_manager.add_friendship_points(_martha.unlock_cost)
		_progression_manager.recruit_partner(&"martha")
		watch_signals(_progression_manager)
		_item_manager.add_friendship_points(10)
		assert_signal_not_emitted(_progression_manager, "partner_recruit_available")


class TestPartnerRecruitPersistence:
	extends GutTest

	func test_deferred_recruit_available_emitted_for_threshold_met_save() -> void:
		var item_manager: Node = ItemFactory.create_manager(self)
		item_manager._progression.total_friendship_points_earned = 200
		item_manager._progression.recruit_offered_partners = [&"martha"] as Array[StringName]
		var progression_manager: Node = ProgressionManagerFactory.create_manager(self, item_manager)
		watch_signals(progression_manager)
		await get_tree().process_frame
		assert_signal_emitted(progression_manager, "partner_recruit_available")

	func test_deferred_recruit_available_not_emitted_when_already_recruited() -> void:
		var item_manager: Node = ItemFactory.create_manager(self)
		item_manager._progression.total_friendship_points_earned = 200
		item_manager._progression.unlocked_partners = [&"martha"] as Array[StringName]
		var progression_manager: Node = ProgressionManagerFactory.create_manager(self, item_manager)
		watch_signals(progression_manager)
		await get_tree().process_frame
		assert_signal_not_emitted(progression_manager, "partner_recruit_available")
