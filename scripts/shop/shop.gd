class_name Shop
extends Node2D

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")

@export var config: ShopConfig = DEFAULT_CONFIG
@export var shop_area: Area2D
@export var soul_label: Label
@export var restock_button: Button

## Ball row layout.
@export var shelf: ShopShelf

## Handles prices tick down and soul mote spawning.
@export var purchase_handler: SoulPurchaseHandler

var _ball_manager: BallManager
var _refresh_count: int = 0
var _purchasing_item: ShopItem = null


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager

	_ball_manager.soul_balance_changed.connect(_on_soul_balance_changed)
	_ball_manager.item_level_changed.connect(_on_item_level_changed)
	purchase_handler.purchase_completed.connect(_on_purchase_completed)

	shelf.item_grabbed.connect(_on_item_grabbed)
	shelf.item_dropped.connect(_on_item_dropped)
	shelf.item_refund_owed.connect(_on_item_refund_owed)
	shelf.item_drop_completed.connect(_on_item_drop_completed)

	_update_soul_label(_ball_manager.get_soul_balance())
	shelf.restock()

	if restock_button != null:
		restock_button.focus_mode = Control.FOCUS_NONE
		if not restock_button.pressed.is_connected(_on_restock_pressed):
			restock_button.pressed.connect(_on_restock_pressed)

	_update_restock_button()


func restock() -> void:
	if _purchasing_item != null:
		return

	var cost: int = _calculate_restock_cost()
	if cost > 0:
		if _ball_manager.get_soul_balance() < cost:
			return
		_ball_manager.subtract_soul(cost)

	shelf.restock()

	_refresh_count += 1

	_update_restock_button()


func _calculate_restock_cost() -> int:
	if _refresh_count == 0:
		return 0

	return max(1, ceili(shelf.total_base_cost() * config.restock_cost_multiplier))


func _on_item_grabbed(item: ShopItem) -> void:
	if _purchasing_item != null:
		return

	_purchasing_item = item

	purchase_handler.drain_soul_purchase(item.soul_catcher, item.purchase_price())

	_update_restock_button()


func _on_item_dropped(item: ShopItem) -> void:
	if _purchasing_item != item:
		return

	_purchasing_item = null

	item.refund()


func _on_purchase_completed() -> void:
	if _purchasing_item == null:
		return

	var item: ShopItem = _purchasing_item

	_purchasing_item = null

	item.accept_payment()


func _on_item_drop_completed(_ball_key: String, _position: Vector2, purchased: bool) -> void:
	_update_restock_button()

	if purchased:
		purchase_handler.settle_purchase()


func _on_item_refund_owed(item: ShopItem) -> void:
	await purchase_handler.refund(item.soul_catcher.global_position)

	item.settle_refund()
	_update_restock_button()


func _on_restock_pressed() -> void:
	restock()


func _update_restock_button() -> void:
	if restock_button == null:
		return

	var cost: int = _calculate_restock_cost()

	if cost == 0:
		restock_button.text = "Restock (Free)"
	else:
		restock_button.text = "Restock (%d Soul)" % cost

	restock_button.disabled = _ball_manager.get_soul_balance() < cost or _purchasing_item != null


func _update_soul_label(balance: int) -> void:
	soul_label.text = "Soul: %d" % balance


func _on_soul_balance_changed(balance: int) -> void:
	_update_soul_label(balance)
	_update_restock_button()


func _on_item_level_changed(ball_key: String) -> void:
	if _ball_manager.get_level(ball_key) <= 0:
		return

	var item: ShopItem = shelf.find_item(ball_key)

	if item != null:
		shelf.remove_item(item)
