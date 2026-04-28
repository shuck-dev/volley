class_name CourtDropTarget
extends DropTarget

## Court target: accepts ball-role items at positions that pass a body projection.
##
## SH-287: `can_accept` runs `PhysicsDirectSpaceState2D.intersect_shape` with the item's
## authored `at_rest_shape` at the candidate position; rejects on overlap with walls,
## partners, other balls. `scale_factor` widens the shape for the expansion-ring fallback
## documented in `designs/01-prototype/22-equip-loop-regime.md`.

var _item_manager: Node
var _reconciler: BallReconciler
var _world: World2D
var _court_bounds: Rect2
var _exclude_rids: Array[RID] = []


func configure(
	item_manager: Node,
	reconciler: BallReconciler,
	world: World2D,
	court_bounds: Rect2,
) -> void:
	_item_manager = item_manager
	_reconciler = reconciler
	_world = world
	_court_bounds = court_bounds


## Held-body grabs free their live ball before polling resumes; pass any RIDs that should
## not count as overlaps (e.g. the held item's own existing body, when it has one).
func set_exclude_rids(rids: Array[RID]) -> void:
	_exclude_rids = rids


func can_accept(item_key: String, position: Vector2, scale_factor: float = 1.0) -> bool:
	if not _is_ball_role(item_key):
		return false
	var clamped: Vector2 = DropTarget.clamp_to_rect(position, _court_bounds)
	if clamped != position:
		# Projection runs at the held position, not the clamped one; if the cursor is
		# outside the court, the target does not accept here. (Inside-venue-but-outside-court
		# release lands via VenueDropTarget, which clamps to court for ball items.)
		return false
	return _projection_clear(item_key, clamped, scale_factor)


func accept(item_key: String, position: Vector2, gesture_velocity: Vector2) -> void:
	if _reconciler == null:
		return
	var clamped: Vector2 = DropTarget.clamp_to_rect(position, _court_bounds)
	_reconciler.bring_into_play(item_key, clamped, gesture_velocity)


func _is_ball_role(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		return false
	return definition.role == &"ball"


func _projection_clear(item_key: String, position: Vector2, scale_factor: float) -> bool:
	if _world == null:
		return true
	var space: PhysicsDirectSpaceState2D = _world.direct_space_state
	if space == null:
		return true
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	var shape: Shape2D = null
	if definition != null and definition.at_rest_shape != null:
		shape = _scaled_shape(definition.at_rest_shape, scale_factor)
	if shape == null:
		# Fallback: a small circle keeps the legacy probe behaviour for items missing an
		# authored shape (the test fixture path) without lying about clearance.
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 14.0 * scale_factor
		shape = circle
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, position)
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
