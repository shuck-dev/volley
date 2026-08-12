class_name KitSlot
extends Control

## A single Ball Kit staging slot. Control-based, not a DropTarget/Area2D: ItemDragController
## hit-tests it in screen space via get_global_rect(), not the world-space drop_targets group.

signal pressed(ball_key: String)

@export var icon: TextureRect
## Set by BallKit when it instances this slot; mirrors the kit's overall capacity.
@export var capacity: int = 3

var _ball_manager: BallManager
var _ball_key: String = ""
var _icon_hidden: bool = false


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager


func _gui_input(event: InputEvent) -> void:
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button == null or not mouse_button.pressed:
		return
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or _ball_key.is_empty():
		return
	pressed.emit(_ball_key)


## Injects a non-autoload BallManager for tests. Must be called before adding to tree.
func configure(ball_manager: Node) -> void:
	_ball_manager = ball_manager


## True when this slot can take `ball_key`: the kit has room, or the slot already holds it.
func can_accept(ball_key: String) -> bool:
	if _ball_key == ball_key:
		return true
	return _ball_manager.get_kit_items().size() < capacity


func accept(ball_key: String) -> void:
	_ball_manager.add_to_kit(ball_key)


## Displays `ball_key`'s icon, or clears the slot when `ball_key` is empty.
func set_displayed_key(ball_key: String, definition: BallDefinition) -> void:
	_ball_key = ball_key
	_apply_icon(definition)


func get_displayed_key() -> String:
	return _ball_key


## Hides the icon while the ball is held elsewhere; the slot still reports itself as the occupant.
func set_icon_hidden(hidden: bool) -> void:
	_icon_hidden = hidden
	_apply_icon(_ball_manager.get_item(_ball_key) if _ball_key != "" else null)


func _apply_icon(definition: BallDefinition) -> void:
	icon.texture = definition.icon if definition != null and not _icon_hidden else null
