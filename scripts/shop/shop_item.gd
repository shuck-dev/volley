class_name ShopItem
extends Control

@export var tooltip: ShopTooltip
@export var art_viewport: SubViewport
@export var art_viewport_container: SubViewportContainer
@export var display_case: Control

var item_definition: ItemDefinition
var _item_manager: Node


func setup(definition: ItemDefinition) -> void:
	item_definition = definition


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if item_definition == null:
		return
	_build_visuals()
	_refresh_owned_visibility()
	_refresh_display_case()
	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func can_be_taken() -> bool:
	if item_definition == null:
		return false
	if _item_manager.get_level(item_definition.key) >= 1:
		return false
	return (
		_item_manager.get_friendship_point_balance()
		>= _item_manager.calculate_cost(item_definition.key)
	)


func build_drag_payload() -> ItemDefinition:
	return item_definition


func build_drag_preview() -> Control:
	# todo: SH-66 wire item_drag_preview.tscn in Phase 3
	return null


func _get_drag_data(_pos: Vector2) -> Variant:
	if not can_be_taken():
		return null
	var preview: Control = build_drag_preview()
	if preview != null:
		set_drag_preview(preview)
	return build_drag_payload()


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


func _refresh_owned_visibility() -> void:
	visible = _item_manager.get_level(item_definition.key) == 0


func _refresh_display_case() -> void:
	display_case.visible = not can_be_taken()


func _get_cost_text() -> String:
	return "%d FP" % _item_manager.calculate_cost(item_definition.key)


func _get_flavor_text() -> String:
	if item_definition.descriptions.is_empty():
		return ""
	var current_level: int = _item_manager.get_level(item_definition.key)
	var index: int = clamp(current_level, 0, item_definition.descriptions.size() - 1)
	return item_definition.descriptions[index]


func _on_mouse_entered() -> void:
	tooltip.visible = true


func _on_mouse_exited() -> void:
	tooltip.hide_tooltip()


func _on_friendship_point_balance_changed(_balance: int) -> void:
	_refresh_display_case()


func _on_item_level_changed(item_key: String) -> void:
	if item_key == item_definition.key:
		_refresh_owned_visibility()
		_refresh_display_case()
