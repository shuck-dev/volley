class_name ShopPanel
extends Control

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

@export var config: ShopConfig = DEFAULT_CONFIG
@export var friendship_label: Label
@export var items_row: HBoxContainer

var preferred_width: int:
	get:
		return config.preferred_width if config != null else DEFAULT_CONFIG.preferred_width

var _item_manager: Node


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_update_friendship_label(_item_manager.get_friendship_point_balance())
	_apply_layout_config()
	_spawn_items()


## Called by ConfigHotReload after `config` has been re-assigned from a reloaded .tres.
func on_config_reloaded() -> void:
	_apply_layout_config()
	for child: Node in items_row.get_children():
		if child is ShopItem:
			child.config = config
			child.refresh_from_config()


func _apply_layout_config() -> void:
	if config == null or items_row == null:
		return
	items_row.position = config.items_row_position


func _spawn_items() -> void:
	for definition: ItemDefinition in _get_visible_items():
		var item: ShopItem = ShopItemScene.instantiate()
		item.name = "ShopItem_%s" % definition.key
		item._item_manager = _item_manager
		item.config = config
		item.setup(definition)
		items_row.add_child(item)


func _get_visible_items() -> Array[ItemDefinition]:
	## For prototype, show the first N unpurchased items up to display_slots.
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
