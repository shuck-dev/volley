class_name Venue
extends Control

const DEV_HUD_SCENE := "res://scenes/dev_hud.tscn"

@export var shop: Node2D
@export var court: Court


func _ready() -> void:
	get_viewport().physics_object_picking = true
	shop.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	if OS.is_debug_build():
		add_child(load(DEV_HUD_SCENE).instantiate())


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop.visible = is_unlocked
