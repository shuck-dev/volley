class_name WorkshopDropTarget
extends DropTarget

var _item_manager: Node
var _drop_area: Area2D
var _workshop: Node


func configure(item_manager: Node, drop_area: Area2D, workshop: Node) -> void:
	_item_manager = item_manager
	_drop_area = drop_area
	_workshop = workshop


func can_accept(item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	if _drop_area == null or _workshop == null or _item_manager == null:
		return false
	if _workshop.has_method(&"is_docked") and _workshop.is_docked():
		return false
	var definition: ItemDefinition = DropTarget.get_definition(_item_manager, item_key)
	if definition == null or definition.role != &"ball":
		return false
	return _position_inside_area(position)


func accept(item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	if _item_manager == null or _workshop == null:
		return
	if _workshop.has_method(&"dock_ball"):
		_workshop.dock_ball(item_key)


func _position_inside_area(world_position: Vector2) -> bool:
	return DropTarget.area_world_rect(_drop_area).has_point(world_position)
