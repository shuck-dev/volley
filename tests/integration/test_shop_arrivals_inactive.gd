## SH-100 shop arrivals land inactive on the matching rack.
##
## Exercises the full shop -> item manager -> rack display chain so the
## contract holds end-to-end, not only in unit-level stubs. The dev panel's
## one-click purchase path must keep auto-placing to the natural target
## (ball on court, equipment on player), skipping the rack entirely.
extends GutTest

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const BallRackScene: PackedScene = preload("res://scenes/ball_rack.tscn")
const GearRackScene: PackedScene = preload("res://scenes/gear_rack.tscn")

const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")
const DoubleKnot: ItemDefinition = preload("res://resources/items/double_knot.tres")

var _shop: Shop
var _item_manager: Node
var _ball_rack: Node2D
var _gear_rack: Node2D


func before_each() -> void:
	var mock_storage: SaveStorage = double(SaveStorage).new()
	stub(mock_storage.write).to_return(true)
	stub(mock_storage.read).to_return("")

	_item_manager = load("res://scripts/items/item_manager.gd").new()
	_item_manager._progression = ProgressionData.new(mock_storage)
	_item_manager._effect_manager = EffectManager.new()
	_item_manager.items.assign([TrainingBall, GripTape, AnkleWeights, Cadence, DoubleKnot])
	_item_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_item_manager)

	_shop = ShopScene.instantiate()
	_shop._item_manager = _item_manager
	add_child_autofree(_shop)

	_ball_rack = BallRackScene.instantiate()
	_ball_rack.configure(_item_manager)
	add_child_autofree(_ball_rack)

	_gear_rack = GearRackScene.instantiate()
	_gear_rack.configure(_item_manager)
	add_child_autofree(_gear_rack)


func _shop_item(item_key: String) -> ShopItem:
	return _shop.items_anchor.get_node("ShopItem_%s" % item_key)


func _take_from_shop(shop_item: ShopItem) -> void:
	# Drive the diegetic drag-as-purchase path through the real input handlers.
	# Press routes through pickup_area.input_event (the player's pointer landing
	# on the shop slot); release routes through ShopItem._input with the cursor
	# parked outside the shop area so the gesture resolves as a purchase.
	# SH-253: every player-AC test drives the real input pipeline end-to-end.
	var viewport: Viewport = shop_item.get_viewport()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	shop_item.pickup_area.input_event.emit(viewport, press, 0)

	var canvas_transform: Transform2D = shop_item.get_canvas_transform()
	var outside_world: Vector2 = _shop.shop_area.global_position + Vector2(10000, 0)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = canvas_transform * outside_world
	shop_item._input(release)


# --- ball rack arrivals ----------------------------------------------------


func test_ball_item_taken_from_shop_appears_on_ball_rack() -> void:
	_take_from_shop(_shop_item(TrainingBall.key))

	var displayed: Array[String] = _ball_rack.get_displayed_keys()
	assert_eq(displayed.size(), 1, "ball rack should gain a slot for the taken ball item")
	assert_eq(displayed[0], TrainingBall.key)


func test_ball_item_taken_from_shop_does_not_appear_on_gear_rack() -> void:
	_take_from_shop(_shop_item(TrainingBall.key))

	assert_eq(
		_gear_rack.get_displayed_keys().size(),
		0,
		"gear rack should ignore ball-role arrivals",
	)


func test_ball_item_taken_from_shop_is_not_on_court() -> void:
	_take_from_shop(_shop_item(TrainingBall.key))

	assert_false(
		_item_manager.is_on_court(TrainingBall.key),
		"shop arrivals stay stored until the player activates them",
	)
	assert_eq(
		_item_manager.get_court_items().size(),
		0,
		"no ball items should enter the court from a shop take",
	)


# --- gear rack arrivals ----------------------------------------------------


func test_equipment_item_taken_from_shop_appears_on_gear_rack() -> void:
	_take_from_shop(_shop_item(GripTape.key))

	var displayed: Array[String] = _gear_rack.get_displayed_keys()
	assert_eq(displayed.size(), 1, "gear rack should gain a slot for the taken equipment item")
	assert_eq(displayed[0], GripTape.key)


func test_equipment_item_taken_from_shop_does_not_appear_on_ball_rack() -> void:
	_take_from_shop(_shop_item(GripTape.key))

	assert_eq(
		_ball_rack.get_displayed_keys().size(),
		0,
		"ball rack should ignore equipment-role arrivals",
	)


# --- inert until activated -------------------------------------------------


func test_shop_take_does_not_apply_stat_effects() -> void:
	var base_paddle_size: float = _item_manager.get_stat(&"paddle_size")

	_take_from_shop(_shop_item(GripTape.key))

	assert_eq(
		_item_manager.get_stat(&"paddle_size"),
		base_paddle_size,
		"shop arrivals must not register effects until the player activates them",
	)


func test_activating_a_shop_arrival_removes_it_from_the_rack() -> void:
	_take_from_shop(_shop_item(GripTape.key))
	assert_eq(
		_gear_rack.get_displayed_keys().size(),
		1,
		"precondition: shop arrival sits on the gear rack",
	)

	_item_manager.activate(GripTape.key)

	assert_eq(
		_gear_rack.get_displayed_keys().size(),
		0,
		"activating should move the item off the rack onto the player",
	)


# --- dev panel one-click path ----------------------------------------------


func test_dev_panel_purchase_places_ball_on_court_not_on_rack() -> void:
	# The dev panel calls ItemManager.purchase(); the one-click contract is that
	# first purchase auto-activates to the natural target for quick iteration.
	_item_manager.purchase(TrainingBall.key)

	assert_true(
		_item_manager.is_on_court(TrainingBall.key),
		"dev-panel purchase should land a ball on the court",
	)
	assert_eq(
		_ball_rack.get_displayed_keys().size(),
		0,
		"dev-panel purchase should skip the rack entirely",
	)


func test_dev_panel_purchase_equips_equipment_not_on_rack() -> void:
	_item_manager.purchase(GripTape.key)

	# An equipped item has a non-STORED placement, so get_kit_items omits it.
	assert_eq(
		_gear_rack.get_displayed_keys().size(),
		0,
		"dev-panel purchase should skip the rack and equip directly",
	)
	assert_eq(
		_item_manager.get_kit_items(&"equipment").size(),
		0,
		"equipment kit should be empty after a dev-panel purchase auto-equips",
	)


func test_dev_panel_purchase_applies_stat_effects_immediately() -> void:
	var base_paddle_size: float = _item_manager.get_stat(&"paddle_size")

	_item_manager.purchase(GripTape.key)

	assert_ne(
		_item_manager.get_stat(&"paddle_size"),
		base_paddle_size,
		"dev-panel purchase should register effects on the same call",
	)
