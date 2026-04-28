class_name VenueDropTarget
extends DropTarget

## Lowest-priority fallback: ball-role releases inside the venue rect clamp to the court edge.

var _item_manager: Node
var _reconciler: BallReconciler
var _venue_bounds: Rect2
var _court_bounds: Rect2


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


func can_accept(item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	if not _is_ball_role(item_key):
		return false
	if _venue_bounds.size == Vector2.ZERO:
		return false
	# Inclusive max-edge check; Rect2.has_point treats max as exclusive.
	var lo: Vector2 = _venue_bounds.position
	var hi: Vector2 = lo + _venue_bounds.size
	return position.x >= lo.x and position.x <= hi.x and position.y >= lo.y and position.y <= hi.y


func accept(item_key: String, position: Vector2, gesture_velocity: Vector2) -> void:
	if _reconciler == null:
		return
	var clamped: Vector2 = DropTarget.clamp_to_rect(position, _court_bounds)
	_reconciler.bring_into_play(item_key, clamped, gesture_velocity)


func _is_ball_role(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		return true
	return definition.role == &"ball"
