class_name CourtDropTarget
extends DropTarget

@export var reconciler: BallReconciler

var item_manager: Node
var _item_manager: Node
var _reconciler: BallReconciler
var _world: World2D
var _exclude_rids: Array[RID] = []


func _ready() -> void:
	_item_manager = item_manager if item_manager != null else ItemManager
	_reconciler = reconciler
	_world = get_viewport().find_world_2d()

	add_to_group(&"drop_targets")


## RIDs to exclude from the projection (e.g. the held item's own body).
func set_exclude_rids(rids: Array[RID]) -> void:
	_exclude_rids = rids


func can_accept(item_key: String, world_position: Vector2, scale_factor: float = 1.0) -> bool:
	if DropTarget.get_definition(_item_manager, item_key) == null:
		return false
	if not contains_point(world_position):
		return false
	return _projection_clear(item_key, world_position, scale_factor)


func accept(item_key: String, world_position: Vector2, gesture_velocity: Vector2) -> void:
	if _reconciler == null:
		return
	_reconciler.bring_into_play(item_key, world_position, gesture_velocity)


func _projection_clear(item_key: String, world_position: Vector2, scale_factor: float) -> bool:
	if _world == null:
		return true
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null or definition.at_rest_shape == null:
		return false
	var shape: Shape2D = _scaled_shape(definition.at_rest_shape, scale_factor)
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, world_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	if not _exclude_rids.is_empty():
		params.exclude = _exclude_rids
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
	if source is CapsuleShape2D:
		var src_cap: CapsuleShape2D = source
		var scaled_cap: CapsuleShape2D = CapsuleShape2D.new()
		scaled_cap.radius = src_cap.radius * scale_factor
		scaled_cap.height = src_cap.height * scale_factor
		return scaled_cap
	# Unknown shape type: fall back to the un-scaled source rather than guessing.
	return source
