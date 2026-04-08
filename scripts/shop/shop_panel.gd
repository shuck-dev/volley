# todo: SH-66 Control rewrite pending. This whole file becomes Control-rooted
# with a ClearanceBox drop target. See designs/01-prototype/04-clearance-drag-drop.md.
class_name ShopPanel
extends Node2D

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")
const COUNTERTOP_Y: float = 290.0
const ITEM_MARGIN: float = 50.0

@export var config: ShopConfig = DEFAULT_CONFIG
@export var friendship_label: Label

var preferred_width: int:
	get:
		return config.preferred_width if config != null else DEFAULT_CONFIG.preferred_width

var _item_manager: Node
var _item_container: Node2D


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_update_friendship_label(_item_manager.get_friendship_point_balance())
	_spawn_items()


func _spawn_items() -> void:
	_item_container = Node2D.new()
	_item_container.name = "ItemContainer"
	add_child(_item_container)

	var visible_items: Array[ItemDefinition] = _get_visible_items()
	if visible_items.is_empty():
		return

	var available_width: float = config.preferred_width - ITEM_MARGIN * 2.0
	var spacing: float = available_width / maxf(visible_items.size() - 1, 1)

	for index: int in visible_items.size():
		var definition: ItemDefinition = visible_items[index]
		var item: ShopItem = ShopItemScene.instantiate()
		item._item_manager = _item_manager
		item.setup(definition)
		item.position = Vector2(ITEM_MARGIN + index * spacing, COUNTERTOP_Y)
		_item_container.add_child(item)


func _get_visible_items() -> Array[ItemDefinition]:
	## For prototype, show the first N unpurchased items up to SLOTS.
	## The rotation system replaces this in production.
	var available: Array[ItemDefinition] = []
	for definition: ItemDefinition in _item_manager.items:
		if _item_manager.get_level(definition.key) < definition.max_level:
			available.append(definition)
		if available.size() >= config.display_slots:
			break
	return available


func _update_friendship_label(balance: int) -> void:
	friendship_label.text = "Friendship: %d" % balance


func _on_friendship_point_balance_changed(balance: int) -> void:
	_update_friendship_label(balance)
