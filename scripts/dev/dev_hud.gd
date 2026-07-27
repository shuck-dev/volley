class_name DevHud
extends CanvasLayer

const PADDLE_DEV_OVERLAY_SCENE := "res://scenes/dev/paddle_dev_overlay.tscn"

@export var clearance_button: Button
@export var dev_panel_container: PanelContainer

var _partner_overlay: Node2D


func _ready() -> void:
	clearance_button.visible = not ProgressionManager.is_shop_unlocked()
	clearance_button.pressed.connect(_on_clearance_button_pressed)
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	var venue: Venue = get_parent()
	venue.court.partner_changed.connect(_on_partner_changed)
	_attach_overlay(venue.court.player_paddle)
	_on_partner_changed()


func _exit_tree() -> void:
	if ProgressionManager.shop_unlocked_changed.is_connected(_on_shop_unlocked_changed):
		ProgressionManager.shop_unlocked_changed.disconnect(_on_shop_unlocked_changed)


func _on_clearance_button_pressed() -> void:
	ProgressionManager.unlock_shop()


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	clearance_button.visible = not is_unlocked


func _on_partner_changed() -> void:
	var venue: Venue = get_parent()

	if is_instance_valid(_partner_overlay):
		_partner_overlay.queue_free()
	_partner_overlay = null

	if venue.court.partner_paddle != null:
		_partner_overlay = _attach_overlay(venue.court.partner_paddle)


func _attach_overlay(paddle: Node) -> Node2D:
	var overlay: Node2D = load(PADDLE_DEV_OVERLAY_SCENE).instantiate()
	paddle.add_child(overlay)
	return overlay
