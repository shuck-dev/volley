class_name VenueDropTarget
extends DropTarget

## Venue floor catch-all target.
##
## SH-287 keeps held items as Node2D tokens (no loose-physics body yet; that arrives in
## SH-314). The venue target accepts inside the venue rect when no other target does:
## ball-role items spawn on the court at the court-clamped position (preserving the
## prior "release inside venue but outside court spawns at the court edge" behaviour);
## equipment items return to their gear rack via the item-manager `deactivate` rule the
## RackDropTarget would have run.
##
## The venue target is the **lowest-priority** target; the controller polls it last.
## It accepts only ball items and only when the strict court projection has failed at
## the held position but the cursor is still inside the venue. This keeps releases
## inside the rally surface playable while the loose-physics rework lands separately.

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
	# Inclusive check on the max edge so a release clamped to the venue corner still
	# resolves (Rect2.has_point treats max as exclusive).
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
