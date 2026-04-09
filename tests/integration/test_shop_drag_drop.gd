extends GutTest

# Full-stack integration for the clearance drag-and-drop flow: instantiate the
# real Shop scene with a fresh ItemManager, exercise ClearanceBox.accept, verify
# the cascade (ownership, balance, signal, ShopItem art visibility, pick indicator).

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
const DoubleKnot: ItemDefinition = preload("res://resources/items/double_knot.tres")
const Spare: ItemDefinition = preload("res://resources/items/spare.tres")

var _shop: Shop
var _item_manager: Node
var _clearance_box: ClearanceBox


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
	## Pre-wire the clearance box's item manager so its _ready does not fall back
	## to the real autoload singleton.
	_clearance_box = _shop.get_node("Margin/Contents/ClearanceBox")
	_clearance_box._item_manager = _item_manager
	add_child_autofree(_shop)


func _shop_item(key: String) -> ShopItem:
	return _shop.items_row.get_node("ShopItem_%s" % key)


# --- spawn ---
func test_shop_spawns_one_item_per_visible_definition() -> void:
	assert_eq(_shop.items_row.get_child_count(), 5)


func test_shop_item_names_use_definition_keys() -> void:
	var keys: Array = []
	for child: Node in _shop.items_row.get_children():
		keys.append(child.name)
	assert_true("ShopItem_grip_tape" in keys)
	assert_true("ShopItem_spare" in keys)


func test_friendship_label_shows_current_balance() -> void:
	assert_eq(_shop.friendship_label.text, "Friendship: 10000")


# --- drop flow ---
func test_accept_marks_item_as_owned() -> void:
	_clearance_box.accept(GripTape)
	assert_eq(_item_manager.get_level("grip_tape"), 1)


func test_accept_deducts_cost_from_balance() -> void:
	var balance_before: int = _item_manager.get_friendship_point_balance()
	_clearance_box.accept(GripTape)
	var cost: int = GripTape.base_cost
	assert_eq(_item_manager.get_friendship_point_balance(), balance_before - cost)


func test_accept_emits_item_taken_signal() -> void:
	watch_signals(_clearance_box)
	_clearance_box.accept(GripTape)
	assert_signal_emitted_with_parameters(_clearance_box, "item_taken", [GripTape])


func test_accept_does_not_apply_stat_effects() -> void:
	var base_stat: float = _item_manager.get_stat(&"paddle_speed")
	_clearance_box.accept(GripTape)
	assert_eq(_item_manager.get_stat(&"paddle_speed"), base_stat)


# --- cascade to shop item ---
func test_taking_item_hides_its_shop_item_art() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	_clearance_box.accept(GripTape)
	assert_false(item.art_viewport_container.visible)


func test_taking_item_keeps_shop_item_root_visible_so_slot_persists() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	_clearance_box.accept(GripTape)
	assert_true(item.visible)


func test_taking_item_does_not_affect_other_shop_items() -> void:
	var other: ShopItem = _shop_item("cadence")
	_clearance_box.accept(GripTape)
	assert_true(other.art_viewport_container.visible)


# --- gating ---
func test_clearance_box_rejects_unaffordable_item() -> void:
	_item_manager._progression.friendship_point_balance = 0
	assert_false(_clearance_box.can_accept(GripTape))


func test_clearance_box_rejects_already_owned_item() -> void:
	_clearance_box.accept(GripTape)
	assert_false(_clearance_box.can_accept(GripTape))


func test_shop_item_refuses_drag_for_unaffordable() -> void:
	_item_manager._progression.friendship_point_balance = 0
	assert_false(_shop_item("grip_tape").can_be_taken())


# --- pick slot ---
func test_pick_indicator_becomes_visible_after_layout() -> void:
	await get_tree().process_frame
	assert_true(_shop.pick_indicator.visible)


func test_pick_indicator_sits_over_rightmost_item() -> void:
	await get_tree().process_frame
	var last_item: Control = _shop.items_row.get_child(_shop.items_row.get_child_count() - 1)
	assert_eq(_shop.pick_indicator.global_position, last_item.global_position)
