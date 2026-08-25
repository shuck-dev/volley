class_name VenueDropTarget
extends DropTarget

## Accepts releases inside the venue rect, placing the ball loose on the floor rather than in play.

## Test seam: overrides the BallTracker autoload with a standalone instance.
var ball_tracker: Node

var ball_manager: Node
var _ball_manager: Node
var _ball_tracker: Node


func _ready() -> void:
	super._ready()
	_ball_manager = ball_manager if ball_manager != null else BallManager
	_ball_tracker = ball_tracker if ball_tracker != null else BallTracker


func can_accept(
	_ball_key: String,
	world_position: Vector2,
	_screen_position: Vector2,
	collision_shape: Shape2D,
) -> bool:
	if not contains_point(world_position):
		return false
	return _projection_clear(world_position, collision_shape)


func accept(
	ball_key: String,
	world_position: Vector2,
	_screen_position: Vector2,
	gesture_velocity: Vector2,
) -> bool:
	if _ball_tracker == null or _ball_manager == null:
		return false
	_ball_tracker.release_into_rest(ball_key, world_position, gesture_velocity)
	_ball_manager.mark_loose_in_venue(ball_key, world_position)
	return true
