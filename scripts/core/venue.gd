class_name Venue
extends Control

const DEV_HUD_SCENE := "res://scenes/dev/dev_hud.tscn"

@export var shop: Shop
@export var court: Court
@export var ball_kit: BallKit


func _ready() -> void:
	get_viewport().physics_object_picking = true
	shop.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	# The Court owns the drag controller; the Kit and Shop are its siblings, so Venue hands it over.
	ball_kit.connect_drag_controller(court.drag_controller)
	shop.connect_drag_controller(court.drag_controller)

	if OS.is_debug_build():
		add_child(load(DEV_HUD_SCENE).instantiate())


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop.visible = is_unlocked
