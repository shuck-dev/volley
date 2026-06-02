## SH-251 + SH-252: drives real `_input(InputEventMouseButton)` through shop and rack drag paths.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
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
var _drag: ItemDragController

# --- shop fixtures -----------------------------------------------------------------------


func _setup_shop() -> void:
	_shop_manager = ItemManagerScript.new()
	_shop_manager.state = ItemState.new()
	_shop_manager.economy = EconomyState.new()
	_shop_manager._effect_manager = EffectManager.new()
	_shop_manager.items.assign([GripTape, AnkleWeights, Cadence, Spare])
	_shop_manager.economy.soul_balance = 10000
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
	_manager = ItemManagerScript.new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	_manager.items.assign(typed_items)
	_manager.economy.soul_balance = 10000
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
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = COURT_BOUNDS
	_drag.venue_bounds = VENUE_BOUNDS
	add_child_autofree(_drag)


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
		if child is Ball:
			result.append(child)
	return result


# --- shop drag-as-purchase mirror under real input --------------------------------------


func test_real_press_then_release_outside_shop_purchases_via_input_path() -> void:
	# Drives the real release path through ShopItem._input(InputEventMouseButton). Cursor is
	# warped outside the shop area so the held token's release lands as a purchase.
	_setup_shop()
	var item: ShopItem = _shop_item("grip_tape")
	var viewport: Viewport = item.get_viewport()
	var balance_before: int = _shop_manager.get_soul_balance()
	var cost: int = GripTape.base_cost

	item.pickup_area.input_event.emit(viewport, _press_event(), 0)
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
		_shop_manager.get_soul_balance(),
		balance_before - cost,
		"Soul debit happens once at release-outside time",
	)


# --- SH-252 (b): drag a live ball back to the rack --------------------------------------


func test_real_press_on_live_ball_then_drag_to_rack_returns_token() -> void:
	# Press the live ball through Ball.input_event (the real player path), follow with a
	_setup_ball_drag()
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var live: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(live, "precondition: live ball is on court")
	var viewport: Viewport = live.get_viewport()

	# Press on the live ball routes through Ball._on_input_event → emits `grabbed` →
	# ItemDragController.grab_live_ball. SH-297: routing lives on the child GrabArea.
	var grab_area: Area2D = live.get_node("GrabArea") as Area2D
	grab_area.input_event.emit(viewport, _press_event(), 0)
	assert_true(_drag.is_dragging(), "live ball press must hand off to the drag controller")

	await get_tree().process_frame
	# Step 3: the live Ball IS the drag target; it survives the grab in OUT_HELD until release.
	assert_true(is_instance_valid(live), "live ball survives the mid-rally grab as the drag target")
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD)

	# Release at the rack drop target via a real mouse-up event with the rack as cursor.
	_drag._input(_release_event_at(RACK_CENTER))

	assert_false(_drag.is_dragging(), "release ends the rack-out gesture")
	assert_false(
		_manager.is_on_court("training_ball"),
		"SH-252 b: live ball dragged to rack must leave court so the rack regrows the token",
	)
	# Registry keeps the Ball; rack-return is a STORED transition, not destruction (DevBallStatePanel persists).
	var still_tracked: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(still_tracked, "Ball stays in registry after rack-return")
	assert_eq(
		still_tracked.play_state,
		Ball.PlayState.STORED,
		"rack-return transitions the Ball to STORED"
	)
