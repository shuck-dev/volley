extends GutTest

# Integration: spawn Shop, exit ShopArea, verify ownership + balance cascade.

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
const DoubleKnot: ItemDefinition = preload("res://resources/items/double_knot.tres")
const Spare: ItemDefinition = preload("res://resources/items/spare.tres")

var _shop: Shop
var _item_manager: Node


func before_each() -> void:
	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_item_manager = load("res://scripts/items/item_manager.gd").new()
	_item_manager._progression = ProgressionData.new(mock_storage)
	_item_manager._effect_manager = EffectManager.new()
	_item_manager.items.assign([GripTape, AnkleWeights, Cadence, DoubleKnot, Spare])
	_item_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_item_manager)

	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)


func _shop_item(key: String) -> ShopItem:
	return _shop.items_anchor.get_node("ShopItem_%s" % key)


# --- spawn ---
func test_shop_spawns_one_item_per_visible_definition() -> void:
	assert_eq(_shop.items_anchor.get_child_count(), 5)


func test_shop_item_names_use_definition_keys() -> void:
	var keys: Array = []
	for child: Node in _shop.items_anchor.get_children():
		keys.append(child.name)
	assert_true("ShopItem_grip_tape" in keys)
	assert_true("ShopItem_spare" in keys)


func test_friendship_label_shows_current_balance() -> void:
	assert_eq(_shop.friendship_label.text, "Friendship: 10000")


# --- purchase flow ---
func test_exiting_shop_area_marks_item_as_owned() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	await _drag_item_out_of_shop_area(item)
	assert_eq(_item_manager.get_level("grip_tape"), 1)


func test_exiting_shop_area_deducts_cost_from_balance() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	var balance_before: int = _item_manager.get_friendship_point_balance()
	await _drag_item_out_of_shop_area(item)
	var cost: int = GripTape.base_cost
	assert_eq(_item_manager.get_friendship_point_balance(), balance_before - cost)


func test_exiting_shop_area_marks_item_taken() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	await _drag_item_out_of_shop_area(item)
	assert_true(item.is_taken())


func test_exiting_shop_area_does_not_affect_other_items() -> void:
	var grip_item: ShopItem = _shop_item("grip_tape")
	var other_item: ShopItem = _shop_item("cadence")
	await _drag_item_out_of_shop_area(grip_item)
	assert_false(other_item.is_taken())


func test_exiting_shop_area_when_unaffordable_does_not_purchase() -> void:
	_item_manager._progression.friendship_point_balance = 0
	var item: ShopItem = _shop_item("grip_tape")
	await _drag_item_out_of_shop_area(item)
	assert_eq(_item_manager.get_level("grip_tape"), 0)


func test_exiting_shop_area_when_already_taken_does_nothing() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	item.mark_taken()
	var balance_before: int = _item_manager.get_friendship_point_balance()
	await _drag_item_out_of_shop_area(item)
	assert_eq(_item_manager.get_friendship_point_balance(), balance_before)


# --- helpers ---
func _drag_item_out_of_shop_area(item: ShopItem) -> void:
	# Emit the signal directly to avoid physics-frame timing in tests.
	_shop.shop_area.body_exited.emit(item)
