class_name RackDropTarget
extends DropTarget

var ball_manager: Node
var _ball_manager: Node


func _ready() -> void:
	_ball_manager = ball_manager if ball_manager != null else BallManager

	add_to_group(&"drop_targets")


func can_accept(ball_key: String, world_position: Vector2, _scale_factor: float = 1.0) -> bool:
	if DropTarget.get_definition(_ball_manager, ball_key) == null:
		return false
	return _position_inside_area(world_position)


func accept(ball_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _ball_manager == null:
		return
	if not _ball_manager.is_on_court(ball_key):
		return
	_ball_manager.deactivate(ball_key)


func _position_inside_area(world_position: Vector2) -> bool:
	return contains_point(world_position)
