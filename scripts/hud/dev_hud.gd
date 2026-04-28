class_name DevHud
extends CanvasLayer

@export var clearance_button: Button


func _ready() -> void:
	clearance_button.visible = not ProgressionManager.is_shop_unlocked()
	clearance_button.pressed.connect(_on_clearance_button_pressed)
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)


func _exit_tree() -> void:
	if ProgressionManager.shop_unlocked_changed.is_connected(_on_shop_unlocked_changed):
		ProgressionManager.shop_unlocked_changed.disconnect(_on_shop_unlocked_changed)


func _on_clearance_button_pressed() -> void:
	ProgressionManager.unlock_shop()


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	clearance_button.visible = not is_unlocked
