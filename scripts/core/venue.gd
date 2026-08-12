class_name Venue
extends Control

const DEV_HUD_SCENE := "res://scenes/dev/dev_hud.tscn"

@export var shop: Node2D
@export var court: Court
@export var ball_kit: BallKitDisplay


func _ready() -> void:
	get_viewport().physics_object_picking = true
	shop.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	if court != null and court.drag_controller != null:
		court.drag_controller.kit = ball_kit
		court.drag_controller.connect_kit()

	if OS.is_debug_build():
		add_child(load(DEV_HUD_SCENE).instantiate())


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop.visible = is_unlocked
