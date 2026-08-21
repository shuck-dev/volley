class_name Shop
extends Node2D

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

@export var config: ShopConfig = DEFAULT_CONFIG
@export var shop_area: Area2D
@export var soul_label: Label
@export var items_anchor: Node2D
@export var restock_button: Button

## Handles prices tick down and soul mote spawning.
@export var purchase_handler: SoulPurchaseHandler

var _ball_manager: BallManager
var _refresh_count: int = 0
var _purchasing_item: ShopItem = null


func _ready() -> void:
	if config == null:
		config = DEFAULT_CONFIG

	if _ball_manager == null:
		_ball_manager = BallManager

	_ball_manager.soul_balance_changed.connect(_on_soul_balance_changed)
	_ball_manager.item_level_changed.connect(_on_item_level_changed)
	purchase_handler.purchase_completed.connect(_on_purchase_completed)

	_update_soul_label(_ball_manager.get_soul_balance())
	_spawn_items()

	if restock_button != null:
		restock_button.focus_mode = Control.FOCUS_NONE
		if not restock_button.pressed.is_connected(_on_restock_pressed):
			restock_button.pressed.connect(_on_restock_pressed)

	_update_restock_button()


func _spawn_items() -> void:
	var visible_items: Array[BallDefinition] = _get_item_pool()
	var count: int = visible_items.size()
	var spacing: float = config.item_spacing
	var start_x: float = -(count - 1) * spacing / 2.0

	for index in count:
		var definition: BallDefinition = visible_items[index]
		var shop_item: ShopItem = ShopItemScene.instantiate()
		shop_item.name = "ShopItem_%s" % definition.key
		shop_item.position = Vector2(start_x + index * spacing, 0.0)
		items_anchor.add_child(shop_item)

		shop_item.configure(_ball_manager, definition)
		shop_item.bind_shop_area(shop_area)
		shop_item.grabbed.connect(_on_item_grabbed)
		shop_item.dropped.connect(_on_item_dropped)
		shop_item.refund_owed.connect(_on_item_refund_owed)
		shop_item.drop_completed.connect(_on_item_drop_completed)


func _get_item_pool() -> Array[BallDefinition]:
	var available: Array[BallDefinition] = _ball_manager.items.duplicate()
	available.shuffle()
	return available.slice(0, config.display_slots)


func _clear_items() -> void:
	_purchasing_item = null

	for child: Node in items_anchor.get_children():
		items_anchor.remove_child(child)
		child.free()


func restock() -> void:
	var cost: int = _calculate_restock_cost()
	if cost > 0:
		if _ball_manager.get_soul_balance() < cost:
			return
		_ball_manager.subtract_soul(cost)

	_clear_items()
	_spawn_items()

	_refresh_count += 1

	_update_restock_button()


func _calculate_restock_cost() -> int:
	if _refresh_count == 0:
		return 0

	var total: int = 0

	for child: Node in items_anchor.get_children():
		var shop_item: ShopItem = child as ShopItem

		if shop_item != null and shop_item.ball_definition != null:
			total += shop_item.ball_definition.base_cost

	return max(1, ceili(total * config.restock_cost_multiplier))


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

	# The last mote lands mid physics flush, where the ball's body cannot be built.
	item.accept_payment.call_deferred()


## The ball was dropped outside the shop, so the purchase can be completed.
func _on_item_drop_completed(_ball_key: String, _position: Vector2, purchased: bool) -> void:
	_update_restock_button.call_deferred()

	if purchased:
		purchase_handler.settle_purchase()


## An item leaving the tree cannot spawn motes, so that soul goes straight back.
func _on_item_refund_owed(item: ShopItem) -> void:
	# Returns once this item's soul has finished streaming home.
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

	# Restocking mid-purchase would free the item the soul is streaming into.
	restock_button.disabled = (
		_ball_manager.get_soul_balance() < cost or _is_purchase_in_progress()
	)


## Whether soul is tied up in an item, so the offering cannot change under it.
func _is_purchase_in_progress() -> bool:
	if _purchasing_item != null:
		return true

	for child: Node in items_anchor.get_children():
		var shop_item: ShopItem = child as ShopItem

		if shop_item != null and shop_item.is_settling():
			return true

	return false


func _update_soul_label(balance: int) -> void:
	soul_label.text = "Soul: %d" % balance


func _on_soul_balance_changed(balance: int) -> void:
	_update_soul_label(balance)
	_update_restock_button()


# Refresh the shop pool when an item is purchased so its tile leaves the table.
# Activate/deactivate leaves level unchanged, so no item_placement_changed subscription.
func _on_item_level_changed(ball_key: String) -> void:
	if _ball_manager.get_level(ball_key) <= 0:
		return

	var node: Node = items_anchor.get_node_or_null("ShopItem_%s" % ball_key)

	if node != null:
		node.queue_free()
