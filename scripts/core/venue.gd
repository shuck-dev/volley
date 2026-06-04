class_name Venue
extends Control

@export var shop: Node2D
@export var court: Court
@export var dev_item_panel: Node
@export var venue_left_bound: Node2D
@export var venue_right_bound: Node2D
@export var venue_ceiling: Node2D
@export var venue_floor: Node2D


func _ready() -> void:
	get_viewport().physics_object_picking = true
	if dev_item_panel != null and court != null:
		dev_item_panel.bind_court(court)
	_wire_drag_clamp()
	shop.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)


func _wire_drag_clamp() -> void:
	if court == null or court.drag_controller == null:
		return
	var drag: ItemDragController = court.drag_controller
	drag.venue_left_bound = venue_left_bound
	drag.venue_right_bound = venue_right_bound
	drag.venue_ceiling = venue_ceiling
	drag.venue_floor = venue_floor
	drag._derive_venue_bounds_from_nodes()


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	shop.visible = is_unlocked
