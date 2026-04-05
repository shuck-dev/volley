class_name ShopPanel
extends Node2D

const SLOTS: int = 5
const COUNTERTOP_Y: float = 300.0
const ITEM_MARGIN: float = 20.0
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

@export var preferred_width: int = 500
@export var friendship_label: Label

var _item_container: Node2D


func _ready() -> void:
	ItemManager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_update_friendship_label(ItemManager.get_friendship_point_balance())
	var shop_camera: Camera2D = $Camera2D
	shop_camera.make_current()
	_spawn_items()


func _spawn_items() -> void:
	_item_container = Node2D.new()
	_item_container.name = "ItemContainer"
	add_child(_item_container)

	var visible_items: Array[ItemDefinition] = _get_visible_items()
	if visible_items.is_empty():
		return

	var item_width: float = 70.0
	var available_width: float = preferred_width - ITEM_MARGIN * 2.0
	var spacing: float = (available_width - item_width) / maxf(visible_items.size() - 1, 1)

	for index: int in visible_items.size():
		var definition: ItemDefinition = visible_items[index]
		var item: ShopItem = ShopItemScene.instantiate()
		item.setup(definition)
		item.position = Vector2(ITEM_MARGIN + index * spacing, COUNTERTOP_Y)
		_item_container.add_child(item)


func _get_visible_items() -> Array[ItemDefinition]:
	## For prototype, show the first N unpurchased items up to SLOTS.
	## The rotation system replaces this in production.
	var available: Array[ItemDefinition] = []
	for definition: ItemDefinition in ItemManager.items:
		if ItemManager.get_level(definition.key) < definition.max_level:
			available.append(definition)
		if available.size() >= SLOTS:
			break
	return available


func _update_friendship_label(balance: int) -> void:
	friendship_label.text = "Friendship: %d" % balance


func _on_friendship_point_balance_changed(balance: int) -> void:
	_update_friendship_label(balance)
