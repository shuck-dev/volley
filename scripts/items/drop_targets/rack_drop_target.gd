class_name RackDropTarget
extends DropTarget

var ball_manager: Node
var _ball_manager: Node


func _ready() -> void:
	_ball_manager = ball_manager if ball_manager != null else BallManager

	add_to_group(&"drop_targets")


func can_accept(_ball_key: String, _world_position: Vector2, _collision_shape: Shape2D) -> bool:
	return false


func accept(_ball_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass
