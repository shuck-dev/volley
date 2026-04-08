class_name SceneLayout
extends Control

const ShopScene: PackedScene = preload("res://scenes/shop.tscn")

## Fallback width for secondary scenes that do not expose a `preferred_width`
## property. Individual scenes override by declaring `@export var preferred_width: int`
## on their root script.
const DEFAULT_SECONDARY_WIDTH: int = 400

@export var game_viewport: SubViewport
@export var hud: CanvasLayer
@export var secondary_container: Control

var _secondary_viewport_container: SubViewportContainer
var _secondary_scene: Node


func _ready() -> void:
	if game_viewport != null:
		game_viewport.transparent_bg = false
	if hud != null:
		hud.shop_button_pressed.connect(_on_shop_button_pressed)
	secondary_container.visible = false


func open_secondary(scene: PackedScene) -> void:
	close_secondary()

	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	secondary_container.add_child(container)
	_secondary_viewport_container = container

	var viewport := SubViewport.new()
	viewport.name = "SecondaryViewport"
	viewport.handle_input_locally = false
	viewport.physics_object_picking = true
	container.add_child(viewport)

	_secondary_scene = scene.instantiate()

	var declared_width: Variant = _secondary_scene.get("preferred_width")
	var panel_width: int = declared_width if declared_width != null else DEFAULT_SECONDARY_WIDTH
	secondary_container.custom_minimum_size.x = panel_width
	secondary_container.visible = true

	# Set viewport size explicitly using the known window height.
	# stretch=true will sync to the correct size once layout settles.
	var window_height: int = int(get_viewport().get_visible_rect().size.y)
	viewport.size = Vector2i(panel_width, window_height)

	viewport.add_child(_secondary_scene)

	# Enable stretch after layout settles so the SVC forwards input correctly.
	await get_tree().process_frame

	# Guard against a concurrent close_secondary() or open_secondary() call
	# that replaced or freed this container during the await.
	if is_instance_valid(container) and container == _secondary_viewport_container:
		container.stretch = true


func close_secondary() -> void:
	if _secondary_viewport_container != null and is_instance_valid(_secondary_viewport_container):
		_secondary_viewport_container.queue_free()
	_secondary_viewport_container = null
	_secondary_scene = null
	if secondary_container != null:
		secondary_container.visible = false


func _on_shop_button_pressed() -> void:
	if _secondary_scene != null:
		close_secondary()
	else:
		open_secondary(ShopScene)
