# todo: move UI elements into the secondary UI viewport for independent scaling
class_name Shop
extends Control

const DEFAULT_CONFIG: ShopConfig = preload("res://resources/shop_config.tres")
const ShopItemScene: PackedScene = preload("res://scenes/shop_item.tscn")

@export var config: ShopConfig = DEFAULT_CONFIG:
	set(value):
		config = value
		if is_inside_tree():
			_apply_config()
			_cascade_config_to_items()
@export var friendship_label: Label
@export var items_row: HBoxContainer
@export var pick_indicator: Control

var preferred_width: int:
	get:
		return config.preferred_width

var _item_manager: Node


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_update_friendship_label(_item_manager.get_friendship_point_balance())
	_spawn_items()
	_apply_config()
	items_row.sort_children.connect(_position_pick_indicator)


## Re-applies shop-level layout values. Child items receive their config during
## spawn, so this function does not cascade; use _cascade_config_to_items() for that.
func _apply_config() -> void:
	if config == null or items_row == null:
		return
	items_row.position = config.items_row_position
	_position_pick_indicator()


func _cascade_config_to_items() -> void:
	for child: Node in items_row.get_children():
		if child is ShopItem:
			child.config = config


func _spawn_items() -> void:
	for definition: ItemDefinition in _get_visible_items():
		var item: ShopItem = ShopItemScene.instantiate()
		item.name = "ShopItem_%s" % definition.key
		item.configure(_item_manager, config, definition)
		items_row.add_child(item)
	_position_pick_indicator.call_deferred()


## Parks the pick indicator over the rightmost spawned item once HBox layout has
## settled. The slot marker is a shop-level concern, so it lives here and not on ShopItem.
func _position_pick_indicator() -> void:
	if pick_indicator == null or items_row.get_child_count() == 0:
		return
	var last_item: Control = items_row.get_child(items_row.get_child_count() - 1)
	pick_indicator.global_position = last_item.global_position
	pick_indicator.size = last_item.size
	pick_indicator.visible = true
	if pick_indicator.get_child_count() > 0:
		var note: Control = pick_indicator.get_child(0)
		note.position = config.pick_note_position


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
