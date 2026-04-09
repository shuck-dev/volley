class_name ClearanceBox
extends PanelContainer

signal item_taken(definition: ItemDefinition)

@export var idle_stylebox: StyleBox
@export var hover_stylebox: StyleBox

var _item_manager: Node


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_set_idle()


func can_accept(definition: ItemDefinition) -> bool:
	if definition == null:
		return false
	return _item_manager.can_acquire(definition.key)


func accept(definition: ItemDefinition) -> void:
	if not _item_manager.take(definition.key):
		return
	item_taken.emit(definition)


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not data is ItemDefinition:
		return false
	var ok: bool = can_accept(data)
	if ok:
		_set_hover()
	else:
		_set_idle()
	return ok


func _drop_data(_pos: Vector2, data: Variant) -> void:
	accept(data)
	_set_idle()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_idle()


func _set_idle() -> void:
	if idle_stylebox != null:
		add_theme_stylebox_override("panel", idle_stylebox)


func _set_hover() -> void:
	if hover_stylebox != null:
		add_theme_stylebox_override("panel", hover_stylebox)
