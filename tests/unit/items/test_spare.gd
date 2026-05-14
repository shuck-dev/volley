extends GutTest

# Spare is a single-purchase court item that expands kit slots.

var _item: ItemDefinition
var _manager: Node


func before_each() -> void:
	_item = preload("res://resources/items/spare.tres")
	_manager = ItemFactory.create_manager(self, _item.key)
	_manager.items.assign([_item])


# --- court item, single purchase ---
func test_type_is_court() -> void:
	assert_eq(_item.type, &"court")


func test_cannot_purchase_after_first_buy() -> void:
	_manager.economy.friendship_point_balance = 100000
	_manager.purchase("spare")
	assert_false(_manager.can_purchase("spare"))


# --- kit slot expansion ---
func test_adds_kit_slot_on_purchase() -> void:
	_manager.economy.friendship_point_balance = 100000
	_manager.purchase("spare")
	assert_eq(
		Stats.resolve(GameRules.base.kit_slots, &"kit_slots", _manager),
		GameRules.base.kit_slots + 1.0,
	)
