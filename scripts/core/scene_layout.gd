class_name SceneLayout
extends Control

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")

@export var game_viewport_container: SubViewportContainer
@export var secondary_container: Control

var _secondary_viewport_container: SubViewportContainer
var _secondary_scene: Node


func _ready() -> void:
	var game_viewport: SubViewport = game_viewport_container.get_node("GameViewport")
	game_viewport.transparent_bg = false

	var game: Node = game_viewport.get_node("Game")
	var hud: CanvasLayer = game.get_node("HUD")
	hud.shop_button_pressed.connect(_on_shop_button_pressed)
	secondary_container.visible = false


func open_secondary(scene: PackedScene) -> void:
	close_secondary()

	_secondary_viewport_container = SubViewportContainer.new()
	_secondary_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	secondary_container.add_child(_secondary_viewport_container)

	var viewport := SubViewport.new()
	viewport.name = "SecondaryViewport"
	viewport.handle_input_locally = false
	_secondary_viewport_container.add_child(viewport)

	_secondary_scene = scene.instantiate()

	var preferred_width: Variant = _secondary_scene.get("preferred_width")
	var panel_width: int = preferred_width if preferred_width != null else 400
	secondary_container.custom_minimum_size.x = panel_width
	secondary_container.visible = true

	## Set viewport size explicitly using the known window height.
	## stretch=true will sync to the correct size once layout settles.
	var window_height: int = int(get_viewport().get_visible_rect().size.y)
	viewport.size = Vector2i(panel_width, window_height)

	viewport.add_child(_secondary_scene)


func close_secondary() -> void:
	if _secondary_viewport_container != null:
		_secondary_viewport_container.queue_free()
		_secondary_viewport_container = null
		_secondary_scene = null
	secondary_container.visible = false


func _on_shop_button_pressed() -> void:
	if _secondary_scene != null:
		close_secondary()
	else:
		open_secondary(ShopScene)
