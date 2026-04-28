extends GutTest

# Integration: spawn Shop, exit ShopArea, verify ownership + balance cascade.

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
const DoubleKnot: ItemDefinition = preload("res://resources/items/double_knot.tres")
const Spare: ItemDefinition = preload("res://resources/items/spare.tres")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")

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


# --- input wiring ---
# Regression guard: every ShopItem must route its Area2D input_event into the
# drag handler. After SH-258 the shop item is a Node2D with a child PickupArea,
# so the wiring lives on that area.
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
		item.pickup_area.input_event.emit(viewport, press, 0)
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
	# SH-253: full press-drag-release through the real input handlers (SH-246 purchase path).
	var item: ShopItem = _shop_item("grip_tape")
	var balance_before: int = _item_manager.get_friendship_point_balance()
	var cost: int = GripTape.base_cost
	var viewport: Viewport = item.get_viewport()

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	item.pickup_area.input_event.emit(viewport, press, 0)

	assert_true(item.is_dragging(), "press starts the held-token gesture")
	assert_eq(_item_manager.get_level("grip_tape"), 0, "press alone must not purchase")

	# Release outside shop bounds via _input; event.position is deterministic under headless.
	var canvas_transform: Transform2D = item.get_canvas_transform()
	var outside_world: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = canvas_transform * outside_world
	item._input(release)

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


# --- SH-320: shop-to-court drag must spawn a live ball, not route to the rack -------


func test_shop_to_court_release_spawns_ball_at_release_position() -> void:
	# Re-stage with a ball-role item that has an at_rest_shape so the court target
	# projection has a real radius. Wire a BallDragController so the shop can route the
	# new ball through it.
	_item_manager.items.assign([TrainingBall] as Array[ItemDefinition])

	# The Shop builds its child items in `_ready`; respawning is the cleanest way to
	# pick up the swapped item list under the integration harness.
	_shop.queue_free()
	await get_tree().process_frame
	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)

	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(_item_manager, host)
	add_child_autofree(reconciler)

	var drag: BallDragController = BallDragControllerScript.new()
	drag.configure(_item_manager, null, null, reconciler)
	drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(drag)
	# Wait one frame so _ready has run and added the controller to drag_controller group.
	await get_tree().process_frame

	var item: ShopItem = _shop.items_anchor.get_node("ShopItem_training_ball")
	item.start_drag()

	# Release inside the court interior but outside the shop area's 500x400 rect.
	var court_release: Vector2 = _shop.shop_area.global_position + Vector2(0, 300)
	item.attempt_release(court_release)

	assert_eq(
		_item_manager.get_level("training_ball"), 1, "purchase committed at outside-shop release"
	)
	var ball: Ball = reconciler.get_ball_for_key("training_ball")
	assert_not_null(
		ball, "shop-to-court release spawns a live ball through the drag controller (SH-320)"
	)
	assert_eq(ball.global_position, court_release, "live ball lands at the released cursor point")


func test_shop_release_outside_court_falls_through_to_rack_default() -> void:
	# A release into a nonsensical far-corner position passes the venue-bounds check on
	# VenueDropTarget at its corner, but a position outside the venue entirely falls
	# through; spawn_purchased_at returns false and the rack regrows the token via the
	# existing court_changed -> rack-refresh path.
	_item_manager.items.assign([TrainingBall] as Array[ItemDefinition])
	_shop.queue_free()
	await get_tree().process_frame
	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)

	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(_item_manager, host)
	add_child_autofree(reconciler)

	var drag: BallDragController = BallDragControllerScript.new()
	drag.configure(_item_manager, null, null, reconciler)
	# Tight venue/court so the far-out position lands clearly outside.
	drag.court_bounds = Rect2(Vector2(-100, -100), Vector2(200, 200))
	drag.venue_bounds = Rect2(Vector2(-200, -200), Vector2(400, 400))
	add_child_autofree(drag)
	await get_tree().process_frame

	var item: ShopItem = _shop.items_anchor.get_node("ShopItem_training_ball")
	item.start_drag()
	# Far outside the venue: target poll cannot accept; falls through to rack-default.
	item.attempt_release(Vector2(99999, 99999))

	assert_eq(_item_manager.get_level("training_ball"), 1, "purchase still committed")
	# spawn_purchased_at returned false; ball did not spawn through the controller.
	assert_null(
		reconciler.get_ball_for_key("training_ball"),
		"far-outside release falls through to the rack-default path, not court spawn",
	)


# --- helpers ---
func _drag_item_out_of_shop_area(item: ShopItem) -> void:
	# Drive the diegetic drag-as-purchase path: press, then release outside the
	# shop bounds. The position is well outside the shop area's collision rect.
	item.start_drag()
	var outside: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	item.attempt_release(outside)
