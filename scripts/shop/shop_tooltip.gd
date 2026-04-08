class_name ShopTooltip
extends Node2D

@export var name_label: Label
@export var cost_label: Label
@export var flavor_label: Label


func show_item(display_name: String, cost_text: String, flavor_text: String) -> void:
	name_label.text = display_name
	cost_label.text = cost_text
	flavor_label.text = flavor_text
	flavor_label.visible = not flavor_text.is_empty()
	visible = true


func update_cost(cost_text: String) -> void:
	cost_label.text = cost_text


func hide_tooltip() -> void:
	visible = false


func follow_mouse(mouse_position: Vector2) -> void:
	var panel: PanelContainer = $Panel
	var panel_size: Vector2 = panel.size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	var offset_x: float = 12.0
	var offset_y: float = -20.0

	## Flip horizontally if tooltip would overflow right edge
	if mouse_position.x + offset_x + panel_size.x > viewport_size.x:
		offset_x = -panel_size.x - 12.0

	## Flip vertically if tooltip would overflow top edge
	if mouse_position.y + offset_y < 0:
		offset_y = 20.0

	global_position = mouse_position + Vector2(offset_x, offset_y)
