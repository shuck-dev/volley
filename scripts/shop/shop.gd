class_name Shop
extends Node2D

## Diegetic shop in the venue. Pressing an item starts a held-token drag; releasing
## outside the shop area completes the purchase. See designs/01-prototype/08-shop.md.

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const ShopDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/shop_drop_target.gd"
)

@export var config: ShopConfig = DEFAULT_CONFIG
@export var shop_area: Area2D
@export var friendship_label: Label
@export var items_anchor: Node2D

var _item_manager: Node


func _ready() -> void:
	if config == null:
		config = DEFAULT_CONFIG
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_update_friendship_label(_item_manager.get_friendship_point_balance())
	_spawn_items()
	_register_shop_target()


## Hands a ShopDropTarget to the drag controller so a release back inside the shop area
## cancels with no purchase. Defers a frame so the controller has time to add itself to
## the `drag_controller` group during its own `_ready`.
func _register_shop_target() -> void:
	call_deferred(&"_do_register_shop_target")


func _do_register_shop_target() -> void:
	var controller: Node = get_tree().get_first_node_in_group(&"drag_controller")
	if controller == null:
		return
	if not controller.has_method("register_target"):
		return
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.configure(shop_area)
	controller.register_target(target)


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
		shop_item.configure(_item_manager, definition)
		shop_item.bind_shop_area(shop_area)


func _get_visible_items() -> Array[ItemDefinition]:
	var available: Array[ItemDefinition] = []
	for definition: ItemDefinition in _item_manager.items:
		if not definition.purchasable:
			continue
		if _item_manager.get_level(definition.key) == 0:
			available.append(definition)
		if available.size() >= config.display_slots:
			break
	return available


func _update_friendship_label(balance: int) -> void:
	friendship_label.text = "Friendship: %d" % balance


func _on_friendship_point_balance_changed(balance: int) -> void:
	_update_friendship_label(balance)


# Refresh the shop pool when an item is purchased so its tile leaves the table.
func _on_item_level_changed(item_key: String) -> void:
	if _item_manager.get_level(item_key) <= 0:
		return
	var node: Node = items_anchor.get_node_or_null("ShopItem_%s" % item_key)
	if node != null:
		node.queue_free()
