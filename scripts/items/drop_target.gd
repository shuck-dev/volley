class_name DropTarget
extends Area2D


func can_accept(_item_key: String, _position: Vector2, _scale_factor: float = 1.0) -> bool:
	return false


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


static func get_definition(item_manager: Node, item_key: String) -> ItemDefinition:
	if item_manager == null:
		return null
	for item: ItemDefinition in item_manager.items:
		if item.key == item_key or BallKey.is_instance(item.key, item_key):
			return item
	return null


## A target with no rectangular collider contains nothing, so it accepts nothing.
func contains_point(world_position: Vector2) -> bool:
	var collision_shape: CollisionShape2D = _get_collision_shape()

	if collision_shape == null:
		return false

	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D

	if rectangle == null:
		return false

	var shape_transform: Transform2D = global_transform * collision_shape.transform

	return rectangle.get_rect().has_point(shape_transform.affine_inverse() * world_position)


func _get_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null
