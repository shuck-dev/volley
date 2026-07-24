class_name RackDropTarget
extends DropTarget

## Accepts role-matched items inside the rack's drop area; deactivates on-court items so the rack regrows.

@export var item_manager: Node
@export var drop_area: Area2D
@export var role: StringName = &"ball"

var _item_manager: Node
var _drop_area: Area2D
var _role: StringName


func _ready() -> void:
	_item_manager = item_manager if item_manager != null else ItemManager
	_drop_area = drop_area
	_role = role

	# Deferred: sibling _ready order is declaration order, and this node can precede the
	# controller, so a same-frame group lookup can race the controller joining the group.
	call_deferred(&"_register_with_controller")


func _register_with_controller() -> void:
	var ctrl: Node = get_tree().get_first_node_in_group(&"drag_controller")
	if ctrl != null:
		ctrl.register_target(self)


func configure(
	item_manager: Node,
	drop_area: Area2D,
	role: StringName,
) -> void:
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
	return DropTarget.area_world_rect(_drop_area).has_point(world_position)
