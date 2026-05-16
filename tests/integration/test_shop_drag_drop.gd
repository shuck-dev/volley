extends GutTest

# Integration: spawn Shop, exit ShopArea, verify ownership + balance cascade.

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
const Spare: ItemDefinition = preload("res://resources/items/spare.tres")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")

var _shop: Shop
var _item_manager: Node


func before_each() -> void:
	_item_manager = ItemManagerScript.new()
	_item_manager.state = ItemState.new()
	_item_manager.economy = EconomyState.new()
	_item_manager._effect_manager = EffectManager.new()
	_item_manager.items.assign([GripTape, AnkleWeights, Cadence, Spare])
	_item_manager.economy.friendship_point_balance = 10000
	add_child_autofree(_item_manager)

	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)


func _shop_item(key: String) -> ShopItem:
	return _shop.items_anchor.get_node("ShopItem_%s" % key)


# --- diegetic drag-as-purchase ---
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


# --- SH-320: shop-to-court drag must spawn a live ball, not route to the rack -------


func test_shop_to_court_release_spawns_ball_at_release_position() -> void:
	# TrainingBall carries an at_rest_shape so CourtDropTarget has a real radius to query.
	_item_manager.items.assign([TrainingBall] as Array[ItemDefinition])

	# Shop builds children in `_ready`; respawn picks up the swapped item list.
	_shop.queue_free()
	await get_tree().process_frame
	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)

	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(_item_manager)
	add_child_autofree(reconciler)

	var drag: BallDragController = BallDragControllerScript.new()
	drag.configure(_item_manager, null, null, reconciler)
	drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(drag)
	# Wait one frame so _ready joins the drag_controller group.
	await get_tree().process_frame

	var item: ShopItem = _shop.items_anchor.get_node("ShopItem_training_ball")
	item.start_drag()

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


func test_shop_release_outside_court_spawns_ball_in_registry_via_falling_body() -> void:
	# Outside the venue rejects every drop target; the ball-role fallthrough drops a Ball directly
	# into the registry (OUT_REST) via release_into_rest instead of the retired HeldBody loose path.
	_item_manager.items.assign([TrainingBall] as Array[ItemDefinition])
	_shop.queue_free()
	await get_tree().process_frame
	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)

	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(_item_manager)
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
	item.attempt_release(Vector2(99999, 99999))

	# Purchase commits inside notify_body_settled, not at release; only the registry Ball must exist now.
	assert_not_null(
		reconciler.get_ball_for_key("training_ball"),
		"ball-role fallthrough lands a registry Ball, not a HeldBody",
	)
