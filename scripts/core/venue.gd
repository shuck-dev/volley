class_name Venue
extends Control

@export var shop: Node2D


func _ready() -> void:
	get_viewport().physics_object_picking = true
	shop.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop.visible = is_unlocked
