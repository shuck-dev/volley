class_name ShopItem
extends Node2D

var item_definition: ItemDefinition

@onready var background: ColorRect = $Background
@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel


func setup(definition: ItemDefinition) -> void:
	item_definition = definition


func _ready() -> void:
	_build_visuals()
	ItemManager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	ItemManager.item_level_changed.connect(_on_item_level_changed)


func _build_visuals() -> void:
	if item_definition == null:
		return
	name_label.text = item_definition.display_name
	_update_cost_label()


func _update_cost_label() -> void:
	var cost: int = ItemManager.calculate_cost(item_definition.key)
	var current_level: int = ItemManager.get_level(item_definition.key)
	if current_level >= item_definition.max_level:
		cost_label.text = "Taken"
	else:
		cost_label.text = "%d FP" % cost


func _on_friendship_point_balance_changed(_balance: int) -> void:
	_update_cost_label()


func _on_item_level_changed(item_key: String) -> void:
	if item_key == item_definition.key:
		_update_cost_label()
