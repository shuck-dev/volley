class_name CourtDropTarget
extends DropTarget

@export var reconciler: BallReconciler

var ball_manager: Node
var _ball_manager: Node
var _reconciler: BallReconciler
var _world: World2D
var _exclude_rids: Array[RID] = []


func _ready() -> void:
	_ball_manager = ball_manager if ball_manager != null else BallManager
	_reconciler = reconciler
	_world = get_viewport().find_world_2d()

	add_to_group(&"drop_targets")


## RIDs to exclude from the projection (e.g. the held item's own body).
func set_exclude_rids(rids: Array[RID]) -> void:
	_exclude_rids = rids


func can_accept(ball_key: String, world_position: Vector2, collision_shape: Shape2D) -> bool:
	if DropTarget.get_definition(_ball_manager, ball_key) == null:
		return false
	if not contains_point(world_position):
		return false
	return _projection_clear(world_position, collision_shape)


func accept(ball_key: String, world_position: Vector2, gesture_velocity: Vector2) -> void:
	if _reconciler == null:
		return
	_reconciler.bring_into_play(ball_key, world_position, gesture_velocity)


func _projection_clear(world_position: Vector2, collision_shape: Shape2D) -> bool:
	if _world == null:
		return true
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	if collision_shape == null:
		return false
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = collision_shape
	params.transform = Transform2D(0.0, world_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	if not _exclude_rids.is_empty():
		params.exclude = _exclude_rids
	return space.intersect_shape(params, 1).is_empty()
