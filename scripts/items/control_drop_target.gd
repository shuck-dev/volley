class_name ControlDropTarget
extends Control

## A drop target in a UI tree, hit-tested in screen space; DropTarget's contract, which Control cannot inherit.

## Lower wins when several targets accept the same release; see ItemDragController.find_accepting_target.
@export var drop_priority: int = 0


func _ready() -> void:
	add_to_group(&"drop_targets")


func can_accept(
	_ball_key: String,
	_world_position: Vector2,
	_screen_position: Vector2,
	_collision_shape: Shape2D
) -> bool:
	assert(false, "ControlDropTarget.can_accept() must be overridden by subclass")
	return false


## Returns true when the target actually took the item, so a refusal leaves it on the cursor.
func accept(
	_ball_key: String,
	_world_position: Vector2,
	_screen_position: Vector2,
	_gesture_velocity: Vector2
) -> bool:
	assert(false, "ControlDropTarget.accept() must be overridden by subclass")
	return false


func contains_screen_point(screen_position: Vector2) -> bool:
	return get_global_rect().has_point(screen_position)
