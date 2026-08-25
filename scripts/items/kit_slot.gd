class_name KitSlot
extends ControlDropTarget

## A single Ball Kit staging slot, and the drop target for the one destination index it owns.

signal pressed(ball_key: String)

## Icon art is not part of BallDefinition (BallManager's boot path loads that eagerly for every
## owned item); the Kit looks it up lazily by convention, only when a slot actually renders one.
const ICON_DIR: String = "res://assets/balls/"
const KIT_DROP_PRIORITY: int = 10

@export var icon: TextureRect
## Set by BallKit when it instances this slot; this slot's own independent destination index.
var slot_index: int = 0

var _ball_manager: BallManager
var _ball_key: String = ""
var _icon_hidden: bool = false


func _ready() -> void:
	super._ready()
	# Below the world targets, so a release over the Kit lands here, not on the court behind it.
	drop_priority = KIT_DROP_PRIORITY
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


## True when the cursor is over this slot and it is empty, or already holds that exact ball.
func can_accept(
	ball_key: String,
	_world_position: Vector2,
	screen_position: Vector2,
	_collision_shape: Shape2D,
) -> bool:
	if ball_key.is_empty() or not contains_screen_point(screen_position):
		return false
	var occupant: String = _ball_manager.get_ball_in_kit_slot(slot_index)
	return occupant == "" or occupant == ball_key


func accept(
	ball_key: String,
	_world_position: Vector2,
	_screen_position: Vector2,
	_gesture_velocity: Vector2,
) -> bool:
	_ball_manager.add_to_kit(ball_key, slot_index)
	return true


## Displays `ball_key`'s icon, or clears the slot when `ball_key` is empty.
func set_displayed_key(ball_key: String) -> void:
	_ball_key = ball_key
	_apply_icon()


func get_displayed_key() -> String:
	return _ball_key


## Hides the icon while the ball is held elsewhere; the slot still reports itself as the occupant.
func set_icon_hidden(hid: bool) -> void:
	_icon_hidden = hid
	_apply_icon()


func _apply_icon() -> void:
	if _ball_key == "" or _icon_hidden:
		icon.texture = null
		return
	var path: String = ICON_DIR + BallKey.base_key(_ball_key) + ".png"
	icon.texture = load(path) if ResourceLoader.exists(path) else null
