extends GutTest

## Shop arrivals land inactive on the matching rack. Dev-panel purchase auto-places balls on
## the court; equipment lands on the gear rack so the player still chooses what fills the kit.

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const BallRackScene: PackedScene = preload("res://scenes/ball_rack.tscn")
const GearRackScene: PackedScene = preload("res://scenes/gear_rack.tscn")

const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const WristBrace: ItemDefinition = preload("res://resources/items/wrist_brace.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")
const Cadence: ItemDefinition = preload("res://resources/items/cadence.tres")

var _shop: Shop
var _item_manager: Node
var _ball_rack: Node2D
var _gear_rack: Node2D


func before_each() -> void:
	_item_manager = load("res://scripts/items/item_manager.gd").new()
	_item_manager.state = ItemState.new()
	_item_manager.economy = EconomyState.new()
	_item_manager._effect_manager = EffectManager.new()
	_item_manager.items.assign([TrainingBall, WristBrace, AnkleWeights, Cadence])
	_item_manager.economy.soul_balance = 10000
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
	# SH-253: drive press + release through the real input handlers end-to-end.
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

# --- gear rack arrivals ----------------------------------------------------
