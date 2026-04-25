## SH-251 + SH-252: drives real `_input(InputEventMouseButton)` through shop and rack drag paths.
## Validates the visibility swap on shop slots, the click-without-movement no-op for rack tokens,
## and the missing rack-out drag for live balls. Mirrors shop drag-as-purchase under real input.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
const DoubleKnot: ItemDefinition = preload("res://resources/items/double_knot.tres")
const Spare: ItemDefinition = preload("res://resources/items/spare.tres")

const COURT_BOUNDS: Rect2 = Rect2(Vector2(-600, -400), Vector2(1200, 800))
const VENUE_BOUNDS: Rect2 = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
const RACK_CENTER: Vector2 = Vector2(-1500, 0)
const RACK_SIZE: Vector2 = Vector2(300, 200)

var _shop: Shop
var _shop_manager: Node
var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController

# --- shop fixtures -----------------------------------------------------------------------


func _setup_shop() -> void:
	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_shop_manager = ItemManagerScript.new()
	_shop_manager._progression = ProgressionData.new(mock_storage)
	_shop_manager._effect_manager = EffectManager.new()
	_shop_manager.items.assign([GripTape, AnkleWeights, Cadence, DoubleKnot, Spare])
	_shop_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_shop_manager)

	_shop = ShopScene.instantiate()
	_shop._item_manager = _shop_manager
	add_child_autofree(_shop)


func _shop_item(key: String) -> ShopItem:
	return _shop.items_anchor.get_node("ShopItem_%s" % key)


func _press_event() -> InputEventMouseButton:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	return press


func _release_event() -> InputEventMouseButton:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	return release


## Mouse-up event with a deterministic viewport position so the controller's canvas-mapped
## release point is reproducible under headless tests.
func _release_event_at(position: Vector2) -> InputEventMouseButton:
	var release := _release_event()
	release.position = position
	return release


# --- ball drag fixtures ------------------------------------------------------------------


func _setup_ball_drag() -> void:
	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_manager = ItemManagerScript.new()
	_manager._progression = ProgressionData.new(mock_storage)
	_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = RackDisplayScript.new()
	_rack.role = &"ball"
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	_rack.add_child(slot_container)
	for index in 4:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	_rack.slot_container = slot_container
	_rack.configure(_manager)
	add_child_autofree(_rack)

	_drop_target = Area2D.new()
	_drop_target.global_position = RACK_CENTER
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = RACK_SIZE
	collision.shape = rectangle
	_drop_target.add_child(collision)
	add_child_autofree(_drop_target)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = COURT_BOUNDS
	_drag.venue_bounds = VENUE_BOUNDS
	add_child_autofree(_drag)


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _host.get_children():
		if child is Ball:
			result.append(child)
	return result


# --- SH-251: shop slot visibility swap ---------------------------------------------------


func test_press_on_shop_item_hides_source_slot_during_drag() -> void:
	_setup_shop()
	var item: ShopItem = _shop_item("grip_tape")
	var viewport: Viewport = item.get_viewport()

	var press := _press_event()
	item.input_event.emit(viewport, press, 0)

	assert_true(item.is_dragging(), "press must start the held-token gesture")
	assert_false(
		item.visible,
		"SH-251: source slot's render must be hidden while the held token follows the cursor",
	)


func test_release_inside_shop_restores_source_slot_visibility() -> void:
	_setup_shop()
	var item: ShopItem = _shop_item("grip_tape")
	var viewport: Viewport = item.get_viewport()

	item.input_event.emit(viewport, _press_event(), 0)
	# Release inside the shop area cancels the purchase; the item must come back into view.
	item.attempt_release(_shop.shop_area.global_position)

	assert_false(item.is_dragging(), "release ends the gesture")
	assert_true(
		item.visible,
		"SH-251: cancelled purchase must restore the source slot's render",
	)
	assert_eq(_shop_manager.get_level("grip_tape"), 0, "cancelled gesture leaves the item unowned")


func test_release_outside_shop_keeps_source_slot_hidden_through_purchase() -> void:
	_setup_shop()
	var item: ShopItem = _shop_item("grip_tape")
	var viewport: Viewport = item.get_viewport()

	item.input_event.emit(viewport, _press_event(), 0)
	var outside: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	item.attempt_release(outside)

	assert_eq(
		_shop_manager.get_level("grip_tape"), 1, "release outside shop completes the purchase"
	)
	assert_false(
		item.visible,
		"SH-251: purchased item stays hidden until the shop refresh removes its node",
	)


# --- shop drag-as-purchase mirror under real input --------------------------------------


func test_real_press_then_release_outside_shop_purchases_via_input_path() -> void:
	# Drives the real release path through ShopItem._input(InputEventMouseButton). Cursor is
	# warped outside the shop area so the held token's release lands as a purchase.
	_setup_shop()
	var item: ShopItem = _shop_item("grip_tape")
	var viewport: Viewport = item.get_viewport()
	var balance_before: int = _shop_manager.get_friendship_point_balance()
	var cost: int = GripTape.base_cost

	item.input_event.emit(viewport, _press_event(), 0)
	assert_true(item.is_dragging(), "press starts the held-token gesture")

	var outside: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	item._input(_release_event_at(outside))

	assert_false(item.is_dragging(), "real mouse-up resolves the gesture")
	assert_eq(
		_shop_manager.get_level("grip_tape"),
		1,
		"release outside shop via real _input must complete the purchase",
	)
	assert_eq(
		_shop_manager.get_friendship_point_balance(),
		balance_before - cost,
		"FP debit happens once at release-outside time",
	)


# --- SH-252 (a): click without movement on a rack token ---------------------------------


func test_real_press_release_on_rack_token_does_not_spawn_a_ball() -> void:
	# Real player path: rack slot press emits via input_event signal, then the controller's
	# _input handler receives the matching release at the same cursor position. No movement
	# means no commit (SH-252 a).
	_setup_ball_drag()
	_manager.take("training_ball")
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	var court_changed_signals: Array = []
	_manager.court_changed.connect(
		func(item_key: String, on_court: bool) -> void:
			court_changed_signals.append([item_key, on_court])
	)

	# Press: simulate the rack slot click at the rack center (where the slot lives).
	_rack.press_slot("training_ball", RACK_CENTER)
	assert_true(_drag.is_dragging(), "rack press must spawn the held token")

	# Release at the same position via a real mouse-up event with no cursor movement.
	_drag._input(_release_event_at(RACK_CENTER))

	assert_false(_drag.is_dragging(), "release must resolve the gesture")
	assert_false(
		_manager.is_on_court("training_ball"),
		"SH-252 a: press-then-release without movement must not introduce the ball",
	)
	assert_null(
		_reconciler.get_ball_for_key("training_ball"),
		"no live Ball must be spawned by a click without movement",
	)
	assert_eq(
		court_changed_signals.size(),
		0,
		"SH-252 a: court_changed must not fire on a click without movement",
	)


# --- SH-252 (b): drag a live ball back to the rack --------------------------------------


func test_real_press_on_live_ball_then_drag_to_rack_returns_token() -> void:
	# Press the live ball through Ball.input_event (the real player path), follow with a
	# release at the rack drop target via the drag controller's _input. Asserts the ball is
	# freed and the item leaves court so the rack regrows the token (SH-252 b).
	_setup_ball_drag()
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var live: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(live, "precondition: live ball is on court")
	var viewport: Viewport = live.get_viewport()

	# Press on the live ball routes through Ball._on_input_event → emits `pressed` →
	# BallDragController.grab_live_ball.
	live.input_event.emit(viewport, _press_event(), 0)
	assert_true(_drag.is_dragging(), "live ball press must hand off to the drag controller")

	await get_tree().process_frame
	assert_false(is_instance_valid(live), "live ball must be freed during the mid-rally grab")

	# Release at the rack drop target via a real mouse-up event with the rack as cursor.
	_drag._input(_release_event_at(RACK_CENTER))

	assert_false(_drag.is_dragging(), "release ends the rack-out gesture")
	assert_false(
		_manager.is_on_court("training_ball"),
		"SH-252 b: live ball dragged to rack must leave court so the rack regrows the token",
	)
	assert_null(
		_reconciler.get_ball_for_key("training_ball"),
		"no Ball should remain tracked after the rack-out release",
	)
