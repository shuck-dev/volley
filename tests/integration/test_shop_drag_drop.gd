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


func test_exiting_shop_area_marks_item_owned() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	await _drag_item_out_of_shop_area(item)
	assert_true(item.is_owned())


func test_exiting_shop_area_does_not_affect_other_items() -> void:
	var grip_item: ShopItem = _shop_item("grip_tape")
	var other_item: ShopItem = _shop_item("cadence")
	await _drag_item_out_of_shop_area(grip_item)
	assert_false(other_item.is_owned())


func test_exiting_shop_area_when_unaffordable_does_not_purchase() -> void:
	_item_manager._progression.friendship_point_balance = 0
	var item: ShopItem = _shop_item("grip_tape")
	await _drag_item_out_of_shop_area(item)
	assert_eq(_item_manager.get_level("grip_tape"), 0)


func test_exiting_shop_area_when_already_owned_does_nothing() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	_item_manager.take("grip_tape")
	var balance_before: int = _item_manager.get_friendship_point_balance()
	await _drag_item_out_of_shop_area(item)
	assert_eq(_item_manager.get_friendship_point_balance(), balance_before)


# --- physics input wiring ---
# Regression guard: every ShopItem must have its input_event signal routed to
# the drag handler. The shipping bug was that a scaled parent silently broke
# physics picking, so a quiet test for "all items respond" is worth keeping.
func test_each_shop_item_responds_to_input_event_signal() -> void:
	var viewport: Viewport = _shop.get_viewport()
	for child in _shop.items_anchor.get_children():
		if not child is ShopItem:
			continue
		var item: ShopItem = child
		var before: int = item.get_last_input_frame()
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		item.input_event.emit(viewport, press, 0)
		assert_ne(item.get_last_input_frame(), before, "input_event not wired for %s" % item.name)


# --- diegetic drag-as-purchase ---
func test_press_on_shop_item_starts_held_token_without_purchase() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	var balance_before: int = _item_manager.get_friendship_point_balance()

	item.start_drag()

	assert_true(item.is_dragging(), "press on an affordable item starts the held-token gesture")
	assert_not_null(item.get_held_token(), "held token spawned on press")
	assert_eq(_item_manager.get_level("grip_tape"), 0, "purchase has not fired yet")
	assert_eq(
		_item_manager.get_friendship_point_balance(),
		balance_before,
		"FP balance unchanged until release outside the shop",
	)


func test_release_inside_shop_cancels_purchase() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	item.start_drag()
	var balance_before: int = _item_manager.get_friendship_point_balance()

	item.attempt_release(_shop.shop_area.global_position)

	assert_false(item.is_dragging(), "release ends the gesture")
	assert_eq(_item_manager.get_level("grip_tape"), 0, "release inside shop must not purchase")
	assert_eq(
		_item_manager.get_friendship_point_balance(),
		balance_before,
		"release inside shop must not debit FP",
	)


func test_release_outside_shop_purchases_and_debits_balance() -> void:
	var item: ShopItem = _shop_item("grip_tape")
	var balance_before: int = _item_manager.get_friendship_point_balance()
	var cost: int = GripTape.base_cost
	item.start_drag()

	var outside: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	item.attempt_release(outside)

	assert_eq(
		_item_manager.get_level("grip_tape"), 1, "release outside shop completes the purchase"
	)
	assert_eq(
		_item_manager.get_friendship_point_balance(),
		balance_before - cost,
		"FP balance debits at release time",
	)


func test_real_press_on_shop_item_starts_drag_and_release_outside_purchases() -> void:
	# Drives InputEventMouseButton through the shop item's input_event signal.
	# Press starts the held token; release outside the shop bounds completes the
	# purchase (SH-246) and lands the item inactive on the matching rack.
	var item: ShopItem = _shop_item("grip_tape")
	var balance_before: int = _item_manager.get_friendship_point_balance()
	var cost: int = GripTape.base_cost
	var viewport: Viewport = item.get_viewport()

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	item.input_event.emit(viewport, press, 0)

	assert_true(item.is_dragging(), "press starts the held-token gesture")
	assert_eq(_item_manager.get_level("grip_tape"), 0, "press alone must not purchase")

	# Release outside shop bounds: drive attempt_release directly (the _input
	# branch reads cursor position from the viewport, which is not deterministic
	# under headless tests).
	var outside: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	item.attempt_release(outside)

	assert_false(item.is_dragging(), "release ends the gesture")
	assert_eq(
		_item_manager.get_level("grip_tape"),
		1,
		"release outside shop completes the purchase (one purchase event)",
	)
	assert_eq(
		_item_manager.get_friendship_point_balance(),
		balance_before - cost,
		"FP balance debits exactly once at release time",
	)
	assert_false(
		_item_manager.is_on_court("grip_tape"),
		"purchased equipment lands inactive on the rack, not on the player",
	)


func test_unaffordable_item_cannot_start_drag() -> void:
	_item_manager._progression.friendship_point_balance = 0
	var item: ShopItem = _shop_item("grip_tape")

	var ok: bool = item.start_drag()

	assert_false(ok, "unaffordable items reject the drag-out gesture")
	assert_false(item.is_dragging(), "no held token when unaffordable")


# --- helpers ---
func _drag_item_out_of_shop_area(item: ShopItem) -> void:
	# Drive the diegetic drag-as-purchase path: press, then release outside the
	# shop bounds. The position is well outside the shop area's collision rect.
	item.start_drag()
	var outside: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	item.attempt_release(outside)
