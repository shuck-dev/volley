class_name VenueDropTarget
extends DropTarget

## Accepts releases inside the venue rect; the controller branches on this type to keep the body alive after release.

@export var reconciler: BallReconciler

var ball_manager: Node
var _ball_manager: Node
var _reconciler: BallReconciler


func _ready() -> void:
	super._ready()
	_ball_manager = ball_manager if ball_manager != null else BallManager
	_reconciler = reconciler

	add_to_group(&"drop_targets")


func can_accept(_ball_key: String, world_position: Vector2, collision_shape: Shape2D) -> bool:
	if not contains_point(world_position):
		return false
	return _projection_clear(world_position, collision_shape)


func accept(_ball_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass
