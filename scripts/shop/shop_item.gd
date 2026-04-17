class_name ShopItem
extends RigidBody2D

## Physics-based shop item: mouse-drag kinematically freezes, release restores gravity.

@export var art_holder: Node2D
@export var collision_shape: CollisionShape2D
@export var case_overlay: Node2D

var item_definition: ItemDefinition

var _item_manager: Node
var _art_instance: ItemArt
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _last_input_frame: int = -1


func configure(item_manager: Node, definition: ItemDefinition) -> void:
	_item_manager = item_manager
	item_definition = definition
	_build_art()
	_refresh_case_overlay()


func can_be_owned() -> bool:
	if item_definition == null or _item_manager == null:
		return false
	return _item_manager.can_acquire(item_definition.key)


## Pickup permission: owned items stay draggable, unowned must be affordable.
func can_be_dragged() -> bool:
	if is_owned():
		return true
	return can_be_owned()


func is_owned() -> bool:
	if item_definition == null or _item_manager == null:
		return false
	return _item_manager.get_level(item_definition.key) > 0


func is_dragging() -> bool:
	return _dragging


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	input_pickable = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	input_event.connect(_on_input_event)
	_item_manager.friendship_point_balance_changed.connect(_on_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_refresh_case_overlay()


func _physics_process(_delta: float) -> void:
	if not _dragging:
		return
	global_position = get_global_mouse_position() + _drag_offset


# Release handled here so a fast drag that outruns collision still ends the drag.
func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
		_end_drag()


func _build_art() -> void:
	if item_definition == null or item_definition.art == null:
		return
	if _art_instance != null and is_instance_valid(_art_instance):
		_art_instance.queue_free()
	_art_instance = item_definition.art.instantiate()
	art_holder.add_child(_art_instance)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	_last_input_frame = Engine.get_physics_frames()
	if mouse_button.pressed and can_be_dragged() and not _dragging:
		_start_drag()


func get_last_input_frame() -> int:
	return _last_input_frame


func _start_drag() -> void:
	_dragging = true
	_drag_offset = global_position - get_global_mouse_position()
	freeze = true


func _end_drag() -> void:
	_dragging = false
	freeze = false


func _on_balance_changed(_balance: int) -> void:
	_refresh_case_overlay()


func _on_item_level_changed(item_key: String) -> void:
	if item_definition != null and item_key == item_definition.key:
		_refresh_case_overlay()


func _refresh_case_overlay() -> void:
	if case_overlay == null:
		return
	if is_owned():
		case_overlay.visible = false
		_refresh_freeze()
		return
	case_overlay.visible = not can_be_owned()
	_refresh_freeze()


# Cased items freeze kinematically; drag lifecycle controls freeze directly.
func _refresh_freeze() -> void:
	if _dragging:
		return
	set_deferred("freeze", not is_owned() and not can_be_owned())
