class_name DevHud
extends CanvasLayer

@export var clearance_button: Button
@export var dev_menu: PanelContainer


func _ready() -> void:
	clearance_button.visible = not ProgressionManager.is_shop_unlocked()
	clearance_button.pressed.connect(_on_clearance_button_pressed)
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	if dev_menu != null and dev_menu.has_method("add_overlay_toggle"):
		dev_menu.add_overlay_toggle("Debug overlays", false, _on_debug_overlay_toggled)
		dev_menu.add_overlay_toggle("Cone follows last hit", false, _on_cone_follow_toggled)

	_apply_debug_overlay(false)

	call_deferred(&"_attach_paddle_overlays")


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


func _attach_paddle_overlays() -> void:
	var overlay_script := load("res://scripts/dev/paddle_dev_overlay.gd")
	for paddle in get_tree().get_nodes_in_group(&"paddles"):
		if paddle.has_node("PaddleDevOverlay"):
			continue
		var overlay: Node = overlay_script.new()
		overlay.name = "PaddleDevOverlay"
		overlay.collision = paddle.collision
		overlay.racket_hitbox = paddle.racket_hitbox
		overlay.racket_shape = paddle.racket_shape
		overlay.sprite = paddle.sprite
		overlay.ground_ray = paddle.ground_ray
		paddle.add_child(overlay)
