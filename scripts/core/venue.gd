class_name Venue
extends Control

const HudScene: PackedScene = preload("res://scenes/hud.tscn")

@export var game_root: Node
@export var game_ui_viewport: SubViewport
@export var secondary_container: Control
@export var shop: Control

var _ui_scale_config := UIScaleConfig.new()
var _hud: CanvasLayer


func _ready() -> void:
	secondary_container.visible = false
	if shop != null:
		secondary_container.custom_minimum_size.x = shop.preferred_width

	_setup_hud()

	# Defer scale application until after stretch has resized the viewport.
	await get_tree().process_frame
	_apply_viewport_scale(game_ui_viewport, &"game")
	game_ui_viewport.size_changed.connect(_on_game_ui_viewport_resized)


func _setup_hud() -> void:
	_hud = HudScene.instantiate()
	game_ui_viewport.add_child(_hud)

	_hud.shop_button_pressed.connect(_on_shop_button_pressed)

	var scale_setting := _hud.get_node_or_null("HudScaleSetting")
	if scale_setting != null:
		scale_setting.set_ui_scale_config(_ui_scale_config)
		scale_setting.scale_applied.connect(func(_value: float) -> void: apply_global_scale())

	if game_root != null:
		game_root.volley_count_changed.connect(_hud.update_volley_count)
		game_root.personal_volley_best_changed.connect(_hud.update_personal_volley_best)
		game_root.ball_speed_updated.connect(_hud.update_speed)
		game_root.auto_play_changed.connect(_hud.update_auto_play)
		game_root.partner_changed.connect(_hud.update_fp_bonus)


func get_ui_scale_config() -> UIScaleConfig:
	return _ui_scale_config


func apply_global_scale() -> void:
	_apply_viewport_scale(game_ui_viewport, &"game")


func _apply_viewport_scale(viewport: SubViewport, viewport_key: StringName) -> void:
	if viewport == null:
		return
	var scale_factor: float = _ui_scale_config.get_viewport_scale(viewport_key)
	if is_equal_approx(scale_factor, 1.0):
		viewport.size_2d_override = Vector2i.ZERO
		viewport.size_2d_override_stretch = false
		return
	var base_size := viewport.size
	var scaled_size := Vector2i(
		roundi(base_size.x / scale_factor),
		roundi(base_size.y / scale_factor),
	)
	viewport.size_2d_override = scaled_size
	viewport.size_2d_override_stretch = true


func _on_game_ui_viewport_resized() -> void:
	_apply_viewport_scale(game_ui_viewport, &"game")


func _on_shop_button_pressed() -> void:
	secondary_container.visible = not secondary_container.visible
