class_name DropTarget
extends RefCounted

## Abstract drop target consulted by BallDragController; first `can_accept` wins.


func can_accept(_item_key: String, _position: Vector2, _scale_factor: float = 1.0) -> bool:
	return false


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


static func get_definition(item_manager: Node, item_key: String) -> ItemDefinition:
	if item_manager == null:
		return null
	for item: ItemDefinition in item_manager.items:
		if item.key == item_key:
			return item
	return null


## Zero-sized bounds pass through so an un-configured court does not collapse releases to origin.
static func clamp_to_rect(world_position: Vector2, bounds: Rect2) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return world_position
	return Vector2(
		clampf(world_position.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clampf(world_position.y, bounds.position.y, bounds.position.y + bounds.size.y),
	)


## Returns empty `Rect2()` when the area is missing/freed or has no rectangular collider.
static func area_world_rect(area: Area2D) -> Rect2:
	if not is_instance_valid(area):
		return Rect2()
	var shape_owner: CollisionShape2D = null
	for child in area.get_children():
		if child is CollisionShape2D:
			shape_owner = child
			break
	if shape_owner == null:
		return Rect2()
	var rectangle: RectangleShape2D = shape_owner.shape as RectangleShape2D
	if rectangle == null:
		return Rect2()
	var half_extents: Vector2 = rectangle.size * 0.5
	var center: Vector2 = area.global_position + shape_owner.position
	return Rect2(center - half_extents, rectangle.size)
