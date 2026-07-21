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
@export var refresh_button: Button
@export var refresh_cost_label: Label

var _item_manager: Node
var _refresh_count: int = 0
## Cached so tree_exiting can unregister after `get_tree()` would return null.
var _registered_target: ShopDropTarget = null
var _registered_controller: Node = null


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
	_update_refresh_ui()
	if refresh_button != null:
		refresh_button.pressed.connect(_on_refresh_pressed)
	if not tree_exiting.is_connected(_on_tree_exiting):
		tree_exiting.connect(_on_tree_exiting)


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
	_registered_target = null
	_registered_controller = null


func _on_refresh_pressed() -> void:
	var cost: int = _get_refresh_cost()
	if cost > 0 and _item_manager.get_soul_balance() < cost:
		return
	if cost > 0:
		_item_manager.subtract_soul(cost)
	_refresh_count += 1
	_clear_items()
	_spawn_items()
	_update_refresh_ui()


func _get_refresh_cost() -> int:
	if _refresh_count == 0:
		return 0
	return int(config.refresh_base_cost * pow(config.refresh_cost_scaling, _refresh_count - 1))


func _update_refresh_ui() -> void:
	if refresh_cost_label == null:
		return
	var cost: int = _get_refresh_cost()
	if cost == 0:
		refresh_cost_label.text = "FREE"
	else:
		refresh_cost_label.text = "%d soul" % cost
	if refresh_button == null:
		return
	refresh_button.disabled = cost > 0 and _item_manager.get_soul_balance() < cost


func _clear_items() -> void:
	for child in items_anchor.get_children():
		child.queue_free()


func _spawn_items() -> void:
	var visible_items: Array[ItemDefinition] = _get_visible_items()
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


func _get_visible_items() -> Array[ItemDefinition]:
	var available: Array[ItemDefinition] = []
	for definition: ItemDefinition in _item_manager.items:
		if not definition.purchasable:
			continue
		if definition.role != &"ball":
			continue
		if _item_manager.get_level(definition.key) == 0:
			available.append(definition)
		if available.size() >= config.display_slots:
			break
	available.shuffle()
	return available


func _update_soul_label(balance: int) -> void:
	soul_label.text = "Soul: %d" % balance


func _on_soul_balance_changed(balance: int) -> void:
	_update_soul_label(balance)


# Refresh the shop pool when an item is purchased so its tile leaves the table.
# Equip/unequip leaves level unchanged, so no item_placement_changed subscription.
func _on_item_level_changed(item_key: String) -> void:
	if _item_manager.get_level(item_key) <= 0:
		return
	var node: Node = items_anchor.get_node_or_null("ShopItem_%s" % item_key)
	if node != null:
		node.queue_free()
