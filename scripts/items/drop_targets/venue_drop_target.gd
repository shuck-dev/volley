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


func can_accept(ball_key: String, world_position: Vector2, scale_factor: float = 1.0) -> bool:
	if not contains_point(world_position):
		return false
	if _world == null:
		return true
	return _projection_clear(ball_key, world_position, scale_factor)


func accept(_ball_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


func _projection_clear(ball_key: String, world_position: Vector2, scale_factor: float) -> bool:
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	var definition: BallDefinition = DropTarget.get_definition(_ball_manager, ball_key)
	if definition == null or definition.at_rest_shape == null:
		return true
	var shape: Shape2D = _scaled_shape(definition.at_rest_shape, scale_factor)
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, world_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	return space.intersect_shape(params, 1).is_empty()


func _scaled_shape(source: Shape2D, scale_factor: float) -> Shape2D:
	if is_equal_approx(scale_factor, 1.0):
		return source
	if source is CircleShape2D:
		var src_circle: CircleShape2D = source
		var scaled_circle: CircleShape2D = CircleShape2D.new()
		scaled_circle.radius = src_circle.radius * scale_factor
		return scaled_circle
	if source is RectangleShape2D:
		var src_rect: RectangleShape2D = source
		var scaled_rect: RectangleShape2D = RectangleShape2D.new()
		scaled_rect.size = src_rect.size * scale_factor
		return scaled_rect
	push_warning(
		(
			"VenueDropTarget._scaled_shape: unscaled %s falls through; expansion-ring projection will be wrong."
			% source.get_class()
		)
	)
	return source
