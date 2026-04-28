class_name RackDropTarget
extends DropTarget

## Rack target: accepts items whose role matches the rack's role at any position inside
## the rack's drop area.
##
## On accept, deactivates the item if it was on-court so the rack regrows the token.
## Pickup-without-movement (a press-release on the source rack with no cursor travel) is
## handled by the drag controller as a bare gesture-cancel; this target is the standard
## return-to-rack drop.

var _item_manager: Node
var _drop_area: Area2D
var _role: StringName


func configure(item_manager: Node, drop_area: Area2D, role: StringName) -> void:
	_item_manager = item_manager
	_drop_area = drop_area
	_role = role


func can_accept(item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	if _drop_area == null:
		return false
	if not _is_role_match(item_key):
		return false
	return _position_inside_area(position)


func accept(item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _item_manager == null:
		return
	if _item_manager.is_on_court(item_key):
		_item_manager.deactivate(item_key)


func _is_role_match(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		# Default to ball-role for backward compat with tests that don't author the field.
		return _role == &"ball"
	return definition.role == _role


func _position_inside_area(world_position: Vector2) -> bool:
	return DropTarget.area_world_rect(_drop_area).has_point(world_position)
