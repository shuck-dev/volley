class_name Shop
extends Node2D

## Diegetic shop in the venue; see designs/01-prototype/08-shop.md.

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const DEFAULT_DRAG_TUNING: ShopDragTuning = preload("res://resources/shop/shop_drag_tuning.tres")

@export var config: ShopConfig = DEFAULT_CONFIG
@export var drag_tuning: ShopDragTuning = DEFAULT_DRAG_TUNING
@export var shop_area: Area2D
@export var soul_label: Label
@export var items_anchor: Node2D
@export var restock_button: Button

var _item_manager: ItemManager
## Cached so tree_exiting can unregister after `get_tree()` would return null.
var _registered_target: ShopDropTarget = null
var _registered_controller: Node = null
var _refresh_count: int = 0


func _ready() -> void:
	if config == null:
		config = DEFAULT_CONFIG
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.soul_balance_changed.connect(_on_soul_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_update_soul_label(_item_manager.get_soul_balance())
	_spawn_items()
	_register_shop_target()
	if not tree_exiting.is_connected(_on_tree_exiting):
		tree_exiting.connect(_on_tree_exiting)
	if restock_button != null:
		restock_button.focus_mode = Control.FOCUS_NONE
		if not restock_button.pressed.is_connected(_on_restock_pressed):
			restock_button.pressed.connect(_on_restock_pressed)
	_update_restock_button()


## Deferred so the controller has run `_ready` and joined the `drag_controller` group.
func _register_shop_target() -> void:
	call_deferred(&"_do_register_shop_target")


func _do_register_shop_target() -> void:
	var controller: Node = get_tree().get_first_node_in_group(&"drag_controller")
	if controller == null:
		return
	if not controller.has_method("register_target"):
		return
	var target: ShopDropTarget = ShopDropTarget.new()
	target.configure(shop_area)
	controller.register_target(target)
	_registered_target = target
	_registered_controller = controller


## Scene reload can free the Shop while the controller lives on, leaving a freed Area2D in the poll.
func _on_tree_exiting() -> void:
	if _registered_target == null:
		return
	if (
		is_instance_valid(_registered_controller)
		and _registered_controller.has_method("unregister_target")
	):
		_registered_controller.unregister_target(_registered_target)
	# The controller no longer parents registered targets, so Shop owns freeing its own.
	_registered_target.free()
	_registered_target = null
	_registered_controller = null


func _spawn_items() -> void:
	var visible_items: Array[ItemDefinition] = _get_item_pool()
	var count: int = visible_items.size()
	var spacing: float = config.item_spacing
	var start_x: float = -(count - 1) * spacing / 2.0
	for index in count:
		var definition: ItemDefinition = visible_items[index]
		var shop_item: ShopItem = ShopItemScene.instantiate()
		shop_item.name = "ShopItem_%s" % definition.key
		shop_item.position = Vector2(start_x + index * spacing, 0.0)
		items_anchor.add_child(shop_item)
		shop_item.tuning = drag_tuning
		shop_item.configure(_item_manager, definition)
		shop_item.bind_shop_area(shop_area)


func _get_item_pool() -> Array[ItemDefinition]:
	var available: Array[ItemDefinition] = []
	for definition: ItemDefinition in _item_manager.items:
		if not definition.purchasable:
			continue
		if definition.role != &"ball":
			continue
		available.append(definition)
	available.shuffle()
	return available.slice(0, config.display_slots)


func _clear_items() -> void:
	for child: Node in items_anchor.get_children():
		items_anchor.remove_child(child)
		child.free()


func restock() -> void:
	var cost: int = _calculate_restock_cost()
	if cost > 0:
		if _item_manager.get_soul_balance() < cost:
			return
		_item_manager.subtract_soul(cost)
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
		if shop_item != null and shop_item.item_definition != null:
			total += shop_item.item_definition.base_cost
	return max(1, ceili(total * config.restock_cost_multiplier))


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
		restock_button.disabled = _item_manager.get_soul_balance() < cost


func _update_soul_label(balance: int) -> void:
	soul_label.text = "Soul: %d" % balance


func _on_soul_balance_changed(balance: int) -> void:
	_update_soul_label(balance)
	_update_restock_button()


# Refresh the shop pool when an item is purchased so its tile leaves the table.
# Equip/unequip leaves level unchanged, so no item_placement_changed subscription.
func _on_item_level_changed(item_key: String) -> void:
	if _item_manager.get_level(item_key) <= 0:
		return
	var node: Node = items_anchor.get_node_or_null("ShopItem_%s" % item_key)
	if node != null:
		node.queue_free()
