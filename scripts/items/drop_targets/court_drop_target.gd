class_name CourtDropTarget
extends DropTarget

## Test seam: overrides the BallTracker autoload with a standalone instance.
var ball_tracker: Node

var ball_manager: Node
var _ball_manager: Node
var _ball_tracker: Node


func _ready() -> void:
	super._ready()
	_ball_manager = ball_manager if ball_manager != null else BallManager
	_ball_tracker = ball_tracker if ball_tracker != null else BallTracker

	add_to_group(&"drop_targets")


func can_accept(_ball_key: String, world_position: Vector2, collision_shape: Shape2D) -> bool:
	if not contains_point(world_position):
		return false
	return _projection_clear(world_position, collision_shape)


func accept(ball_key: String, world_position: Vector2, gesture_velocity: Vector2) -> void:
	if _ball_tracker == null:
		return
	_ball_tracker.bring_into_play(ball_key, world_position, gesture_velocity)
