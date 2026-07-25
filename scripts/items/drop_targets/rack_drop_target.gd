class_name RackDropTarget
extends DropTarget

@export var role: StringName = &"ball"

var item_manager: Node
var _item_manager: Node
var _role: StringName


func _ready() -> void:
	_item_manager = item_manager if item_manager != null else ItemManager
	_role = role

	add_to_group(&"drop_targets")


func can_accept(item_key: String, world_position: Vector2, _scale_factor: float = 1.0) -> bool:
	if not _is_role_match(item_key):
		return false
	return _position_inside_area(world_position)


func accept(item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _item_manager == null:
		return
	if not _item_manager.is_on_court(item_key):
		return
	# Equipment teardown is signal-driven: CharacterDropTarget frees the visual on the EQUIPPED -> STORED transition.
	if _role == &"equipment":
		_item_manager.unequip(item_key)
	else:
		_item_manager.deactivate(item_key)


func _is_role_match(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		# Default to ball-role for backward compat with tests that don't author the field.
		return _role == &"ball"
	return definition.role == _role


func _position_inside_area(world_position: Vector2) -> bool:
	return contains_point(world_position)
