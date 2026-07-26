class_name RackDropTarget
extends DropTarget

var item_manager: Node
var _item_manager: Node


func _ready() -> void:
	_item_manager = item_manager if item_manager != null else ItemManager

	add_to_group(&"drop_targets")


func can_accept(item_key: String, world_position: Vector2, _scale_factor: float = 1.0) -> bool:
	if DropTarget.get_definition(_item_manager, item_key) == null:
		return false
	return _position_inside_area(world_position)


func accept(item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _item_manager == null:
		return
	if not _item_manager.is_on_court(item_key):
		return
	_item_manager.deactivate(item_key)


func _position_inside_area(world_position: Vector2) -> bool:
	return contains_point(world_position)
