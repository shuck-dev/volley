class_name Shop
extends Node2D

## Diegetic shop embedded in the venue. Spawns ShopItem rigid bodies above the
## table. Purchases fire when a ShopItem is dragged or pushed out of ShopArea;
## design: designs/01-prototype/08-shop.md.

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

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
	_update_friendship_label(_item_manager.get_friendship_point_balance())
	shop_area.body_exited.connect(_on_body_exited_shop_area)
	_spawn_items()


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


func _get_visible_items() -> Array[ItemDefinition]:
	var available: Array[ItemDefinition] = []
	for definition: ItemDefinition in _item_manager.items:
		if _item_manager.get_level(definition.key) < definition.max_level:
			available.append(definition)
		if available.size() >= config.display_slots:
			break
	return available


func _on_body_exited_shop_area(body: Node2D) -> void:
	if not body is ShopItem:
		return
	var shop_item: ShopItem = body
	if shop_item.is_taken():
		return
	if not _item_manager.take(shop_item.item_definition.key):
		return
	shop_item.mark_taken()


func _update_friendship_label(balance: int) -> void:
	friendship_label.text = "Friendship: %d" % balance


func _on_friendship_point_balance_changed(balance: int) -> void:
	_update_friendship_label(balance)
