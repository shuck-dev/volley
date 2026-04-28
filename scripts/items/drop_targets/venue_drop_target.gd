class_name VenueDropTarget
extends DropTarget

## Accepts releases inside the venue rect; the controller branches on this type to keep the body alive after release.

var _item_manager: Node
var _reconciler: BallReconciler
var _venue_bounds: Rect2
var _court_bounds: Rect2
var _world: World2D


func configure(
	item_manager: Node,
	reconciler: BallReconciler,
	venue_bounds: Rect2,
	court_bounds: Rect2,
) -> void:
	_item_manager = item_manager
	_reconciler = reconciler
	_venue_bounds = venue_bounds
	_court_bounds = court_bounds


func set_world(world: World2D) -> void:
	_world = world


func can_accept(item_key: String, position: Vector2, scale_factor: float = 1.0) -> bool:
	if _venue_bounds.size == Vector2.ZERO:
		return false
	# Inclusive max-edge check; Rect2.has_point treats max as exclusive.
	var lo: Vector2 = _venue_bounds.position
	var hi: Vector2 = lo + _venue_bounds.size
	var inside: bool = (
		position.x >= lo.x and position.x <= hi.x and position.y >= lo.y and position.y <= hi.y
	)
	if not inside:
		return false
	if _world == null:
		return true
	return _projection_clear(item_key, position, scale_factor)


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


func _projection_clear(item_key: String, position: Vector2, scale_factor: float) -> bool:
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null or definition.at_rest_shape == null:
		return true
	var shape: Shape2D = _scaled_shape(definition.at_rest_shape, scale_factor)
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, position)
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
