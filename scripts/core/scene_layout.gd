class_name SceneLayout
extends Control

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")
const HudScene: PackedScene = preload("res://scenes/hud.tscn")

## Fallback width for secondary scenes that do not expose a `preferred_width`.
## Individual scenes override by declaring `@export var preferred_width: int`.
const DEFAULT_SECONDARY_WIDTH: int = 400

@export var game_content_viewport: SubViewport
@export var game_root: Node
@export var game_ui_viewport: SubViewport
@export var secondary_container: Control

var _secondary_slot: Control
var _secondary_scene: Node
var _secondary_ui_container: SubViewportContainer
var _secondary_ui_viewport: SubViewport
var _ui_scale_config := UIScaleConfig.new()
var _hud: CanvasLayer


func _ready() -> void:
	if game_content_viewport != null:
		game_content_viewport.transparent_bg = false
	secondary_container.visible = false

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


func open_secondary(scene: PackedScene) -> void:
	close_secondary()

	# Content viewport
	var content_container := SubViewportContainer.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	var content_viewport := SubViewport.new()
	content_viewport.name = "SecondaryContentViewport"
	content_viewport.handle_input_locally = false
	content_viewport.physics_object_picking = true
	content_container.add_child(content_viewport)

	# todo: move secondary scene UI elements (shop buttons, prices, drag targets)
	# into this viewport so they scale independently from content.
	# See designs/01-prototype/20-hud-scaling.md
	var ui_container := SubViewportContainer.new()
	ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_container.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_container.visible = false

	var ui_viewport := SubViewport.new()
	ui_viewport.name = "SecondaryUIViewport"
	ui_viewport.transparent_bg = true
	ui_viewport.handle_input_locally = false
	ui_container.add_child(ui_viewport)

	# Slot wrapper
	var slot := Control.new()
	slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(content_container)
	slot.add_child(ui_container)
	secondary_container.add_child(slot)
	_secondary_slot = slot
	_secondary_ui_container = ui_container
	_secondary_ui_viewport = ui_viewport

	_secondary_scene = scene.instantiate()

	var declared_width: Variant = _secondary_scene.get("preferred_width")
	var panel_width: int = declared_width if declared_width != null else DEFAULT_SECONDARY_WIDTH
	secondary_container.custom_minimum_size.x = panel_width
	secondary_container.visible = true

	# Set viewport size explicitly using the known window height.
	# stretch=true will sync to the correct size once layout settles.
	var window_height: int = int(get_viewport().get_visible_rect().size.y)
	content_viewport.size = Vector2i(panel_width, window_height)
	ui_viewport.size = Vector2i(panel_width, window_height)

	content_viewport.add_child(_secondary_scene)

	ui_viewport.size_changed.connect(
		func() -> void:
			if is_instance_valid(ui_viewport):
				_apply_viewport_scale(ui_viewport, &"secondary")
	)

	# Enable stretch after layout settles so the SVC forwards input correctly.
	await get_tree().process_frame

	# Guard against a concurrent close_secondary() or open_secondary() call
	# that replaced or freed this container during the await.
	if is_instance_valid(slot) and slot == _secondary_slot:
		content_container.stretch = true
		ui_container.stretch = true
		_apply_viewport_scale(ui_viewport, &"secondary")


func close_secondary() -> void:
	if _secondary_slot != null and is_instance_valid(_secondary_slot):
		_secondary_slot.queue_free()
	_secondary_slot = null
	_secondary_scene = null
	_secondary_ui_container = null
	_secondary_ui_viewport = null
	if secondary_container != null:
		secondary_container.visible = false


func get_ui_scale_config() -> UIScaleConfig:
	return _ui_scale_config


func apply_global_scale() -> void:
	_apply_viewport_scale(game_ui_viewport, &"game")
	if _secondary_ui_viewport != null and is_instance_valid(_secondary_ui_viewport):
		_apply_viewport_scale(_secondary_ui_viewport, &"secondary")


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
	if _secondary_scene != null:
		close_secondary()
	else:
		open_secondary(ShopScene)
