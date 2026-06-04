class_name Venue
extends Control

@export var shop: Node2D
@export var court: Court
@export var dev_item_panel: Node


func _ready() -> void:
	get_viewport().physics_object_picking = true
	if dev_item_panel != null and court != null:
		dev_item_panel.bind_court(court)
	shop.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop.visible = is_unlocked
