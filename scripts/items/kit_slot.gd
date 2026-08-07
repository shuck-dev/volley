class_name KitSlot
extends Control

## A single Ball Kit staging slot. Control-based, not a DropTarget/Area2D: ItemDragController
## hit-tests it in screen space via get_global_rect(), not the world-space drop_targets group.

@export var icon: TextureRect
## Set by BallKitDisplay when it instances this slot; mirrors the kit's overall capacity.
@export var capacity: int = 3

var _ball_manager: BallManager
var _ball_key: String = ""


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager


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

	if icon == null:
		return

	icon.texture = definition.icon if definition != null else null


func get_displayed_key() -> String:
	return _ball_key
