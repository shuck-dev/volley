class_name DevHud
extends CanvasLayer

@export var clearance_button: Button
@export var dev_panel_container: PanelContainer
@export var dev_menu: PanelContainer


func _ready() -> void:
	clearance_button.visible = not ProgressionManager.is_shop_unlocked()
	clearance_button.pressed.connect(_on_clearance_button_pressed)
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	if dev_menu != null and dev_menu.has_method("add_overlay_toggle"):
		dev_menu.add_overlay_toggle("Debug overlays", false, _on_debug_overlay_toggled)
		dev_menu.add_overlay_toggle("Cone follows last hit", false, _on_cone_follow_toggled)

	_apply_debug_overlay(false)


func _exit_tree() -> void:
	if ProgressionManager.shop_unlocked_changed.is_connected(_on_shop_unlocked_changed):
		ProgressionManager.shop_unlocked_changed.disconnect(_on_shop_unlocked_changed)


func _on_clearance_button_pressed() -> void:
	ProgressionManager.unlock_shop()


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	clearance_button.visible = not is_unlocked


func _on_debug_overlay_toggled(pressed: bool) -> void:
	_apply_debug_overlay(pressed)


func _on_cone_follow_toggled(pressed: bool) -> void:
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay is DevBounceOverlay:
			overlay.follow_last_hit = pressed
			overlay.queue_redraw()


func _apply_debug_overlay(pressed: bool) -> void:
	GrabArea.set_debug_visible(pressed, get_tree())
	for overlay in get_tree().get_nodes_in_group(&"dev_overlays"):
		if overlay.has_method("set_dev_visible"):
			overlay.set_dev_visible(pressed)
