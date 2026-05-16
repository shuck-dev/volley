class_name CharacterDropTarget
extends DropTarget

## Accepts equipment-role items dropped on the main character during the equip pose; capacity gate lives in ItemManager.equip.

var _item_manager: Node
var _drop_area: Area2D
var _timeout_controller: TimeoutController


func configure(
	item_manager: Node, drop_area: Area2D, timeout_controller: TimeoutController
) -> void:
	_item_manager = item_manager
	_drop_area = drop_area
	_timeout_controller = timeout_controller


func can_accept(item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	if _drop_area == null or _item_manager == null:
		return false
	if not _is_equipment_role(item_key):
		return false
	if _item_manager.get_kit_remaining() < 1:
		return false
	if _timeout_controller == null:
		return false
	if _timeout_controller.get_state() != TimeoutController.State.AT_EQUIP_POSE:
		return false
	return _position_inside_area(position)


func accept(item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _item_manager == null:
		return
	# equip emits equip_refused on capacity races; no-op on failure so the held token stays put.
	_item_manager.equip(item_key)


func _is_equipment_role(item_key: String) -> bool:
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null:
		return false
	return definition.role == &"equipment"


func _position_inside_area(world_position: Vector2) -> bool:
	return DropTarget.area_world_rect(_drop_area).has_point(world_position)
