class_name RackDropTarget
extends DropTarget

## Accepts role-matched items inside the rack's drop area; deactivates on-court items so the rack regrows.

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
	if not _item_manager.is_on_court(item_key):
		return
	# Equipment goes through unequip so the rack reads as the inverse of CharacterDropTarget's equip.
	if _role == &"equipment":
		_item_manager.unequip(item_key)
		_free_equipped_visual(item_key)
	else:
		_item_manager.deactivate(item_key)


func _free_equipped_visual(item_key: String) -> void:
	if _drop_area == null or not _drop_area.is_inside_tree():
		return
	var group: StringName = CharacterDropTarget.equipped_art_group(item_key)
	for visual: Node in _drop_area.get_tree().get_nodes_in_group(group):
		visual.queue_free()


func _is_role_match(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		# Default to ball-role for backward compat with tests that don't author the field.
		return _role == &"ball"
	return definition.role == _role


func _position_inside_area(world_position: Vector2) -> bool:
	return DropTarget.area_world_rect(_drop_area).has_point(world_position)
