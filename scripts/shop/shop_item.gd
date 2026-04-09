class_name ShopItem
extends Control

signal case_tapped

const ItemDraggingScene: PackedScene = preload("res://scenes/items/item_dragging.tscn")

@export var tooltip: ShopTooltip
@export var art_viewport: SubViewport
@export var art_viewport_container: SubViewportContainer
@export var display_case: Control
@export var tink_sound: AudioStreamPlayer

var item_definition: ItemDefinition
var config: ShopConfig:
	set(value):
		config = value
		if _bounds_size != Vector2.ZERO:
			_size_display_case(_bounds_size)
var _item_manager: Node
var _bounds_size: Vector2
var _dragging: bool = false


func setup(definition: ItemDefinition) -> void:
	item_definition = definition


## Public injection entry point so Shop._spawn_items does not touch private fields.
func configure(item_manager: Node, item_config: ShopConfig, definition: ItemDefinition) -> void:
	_item_manager = item_manager
	config = item_config
	setup(definition)


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if item_definition == null:
		return
	## top_level lifts the tooltip out of sibling draw order; swap to a shared tooltip later.
	tooltip.top_level = true
	_build_visuals()
	_refresh_owned_visibility()
	_refresh_display_case()
	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	display_case.gui_input.connect(_on_display_case_gui_input)


func can_be_taken() -> bool:
	if item_definition == null:
		return false
	return _item_manager.can_acquire(item_definition.key)


func build_drag_payload() -> ItemDefinition:
	return item_definition


func build_drag_preview() -> Control:
	var dragging: ItemDragging = ItemDraggingScene.instantiate()
	dragging.show_item(item_definition)
	## Wrapper offsets the child to centre it on cursor; mouse-ignore so it does not block drops.
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(dragging)
	dragging.position = -dragging.visible_size / 2.0
	return wrapper


func _get_drag_data(_pos: Vector2) -> Variant:
	if not can_be_taken():
		return null
	var preview: Control = build_drag_preview()
	if preview != null:
		DragManager.show_preview(preview)
	## Hide the source art so the slot looks empty mid-drag; restored on DRAG_END.
	art_viewport_container.visible = false
	return build_drag_payload()


func _notification(what: int) -> void:
	if item_definition == null:
		return
	if what == NOTIFICATION_DRAG_BEGIN:
		_dragging = true
		tooltip.hide_tooltip()
	elif what == NOTIFICATION_DRAG_END:
		_dragging = false
		DragManager.hide_preview()
		_refresh_owned_visibility()


func _build_visuals() -> void:
	if item_definition.art != null:
		var art_instance: ItemArt = item_definition.art.instantiate()
		art_viewport.add_child(art_instance)
		_fit_to_art(art_instance)
	tooltip.show_item(item_definition.display_name, _get_cost_text(), _get_flavor_text())
	tooltip.hide_tooltip()


func _fit_to_art(art_instance: ItemArt) -> void:
	var bounds: Rect2 = art_instance.bounding_rect
	if bounds.size == Vector2.ZERO:
		return
	## Shift the art so its visible top-left lands at the viewport origin.
	art_instance.position -= bounds.position
	art_viewport.size = Vector2i(bounds.size.ceil())
	art_viewport_container.custom_minimum_size = bounds.size
	custom_minimum_size = bounds.size
	_bounds_size = bounds.size
	_size_display_case(_bounds_size)


## Extends the display case beyond the item rect proportionally so the cloche
## has headroom for its dome and margin around the contents.
func _size_display_case(item_size: Vector2) -> void:
	if config == null:
		return
	var padding: Vector3 = config.display_case_padding
	var case_scale: float = config.display_case_scale
	var horizontal_padding: float = item_size.x * padding.x * case_scale
	var top_padding: float = item_size.y * padding.y * case_scale
	var bottom_padding: float = item_size.y * padding.z * case_scale
	display_case.offset_left = -horizontal_padding
	display_case.offset_top = -top_padding
	display_case.offset_right = horizontal_padding
	display_case.offset_bottom = bottom_padding


func _refresh_owned_visibility() -> void:
	## Hide only the art so the slot keeps its place in the row.
	var owned: bool = _item_manager.get_level(item_definition.key) >= 1
	art_viewport_container.visible = not owned
	if owned:
		tooltip.hide_tooltip()


func _refresh_display_case() -> void:
	## Display case marks unaffordable items; owned slots are empty, not behind glass.
	var owned: bool = _item_manager.get_level(item_definition.key) >= 1
	display_case.visible = not owned and not can_be_taken()


func _get_cost_text() -> String:
	return "%d FP" % _item_manager.calculate_cost(item_definition.key)


func _get_flavor_text() -> String:
	if item_definition.descriptions.is_empty():
		return ""
	var current_level: int = _item_manager.get_level(item_definition.key)
	var index: int = clamp(current_level, 0, item_definition.descriptions.size() - 1)
	return item_definition.descriptions[index]


func _on_mouse_entered() -> void:
	if _dragging or _item_manager.get_level(item_definition.key) >= 1:
		return
	tooltip.follow_mouse(get_global_mouse_position())
	tooltip.visible = true


func _on_mouse_exited() -> void:
	tooltip.hide_tooltip()


func _gui_input(event: InputEvent) -> void:
	if _dragging:
		return
	if event is InputEventMouseMotion:
		tooltip.follow_mouse(get_global_mouse_position())


func _on_display_case_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if tink_sound != null:
		tink_sound.play()
	case_tapped.emit()


func _on_friendship_point_balance_changed(_balance: int) -> void:
	_refresh_display_case()


func _on_item_level_changed(item_key: String) -> void:
	if item_key == item_definition.key:
		_refresh_owned_visibility()
		_refresh_display_case()
