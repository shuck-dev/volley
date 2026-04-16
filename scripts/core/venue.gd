class_name Venue
extends Control

# todo: sh-104 revisit canvas_items stretch (godot#86563 blurs text off-native);
# disabled stretch + responsive UI or diegetic + msdf is the long-term fix.

@export var game_root: Node
@export var secondary_container: Control
@export var shop: Control
@export var hud: Hud


func _ready() -> void:
	if shop != null:
		secondary_container.custom_minimum_size.x = shop.preferred_width
	secondary_container.visible = ProgressionManager.is_shop_unlocked()
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	if game_root != null:
		game_root.volley_count_changed.connect(hud.update_volley_count)
		game_root.personal_volley_best_changed.connect(hud.update_personal_volley_best)
		game_root.ball_speed_updated.connect(hud.update_speed)
		game_root.auto_play_changed.connect(hud.update_auto_play)
		game_root.partner_changed.connect(hud.update_fp_bonus)


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	secondary_container.visible = is_unlocked
