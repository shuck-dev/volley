class_name VenueDropTarget
extends DropTarget

## Accepts releases inside the venue rect; the controller branches on this type to keep the body alive after release.

@export var reconciler: BallReconciler

var ball_manager: Node
var _ball_manager: Node
var _reconciler: BallReconciler
var _world: World2D


func _ready() -> void:
	_ball_manager = ball_manager if ball_manager != null else BallManager
	_reconciler = reconciler
	_world = get_viewport().find_world_2d()

	add_to_group(&"drop_targets")


func set_world(world: World2D) -> void:
	_world = world


func can_accept(_ball_key: String, world_position: Vector2, collision_shape: Shape2D) -> bool:
	if not contains_point(world_position):
		return false
	if _world == null:
		return true
	return _projection_clear(world_position, collision_shape)


func accept(_ball_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


func _projection_clear(world_position: Vector2, collision_shape: Shape2D) -> bool:
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	if collision_shape == null:
		return true
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = collision_shape
	params.transform = Transform2D(0.0, world_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	return space.intersect_shape(params, 1).is_empty()
