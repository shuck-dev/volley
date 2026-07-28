class_name DropTarget
extends Area2D


func can_accept(_ball_key: String, _position: Vector2, _collision_shape: Shape2D) -> bool:
	return false


func accept(_ball_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


static func get_definition(ball_manager: Node, ball_key: String) -> BallDefinition:
	if ball_manager == null:
		return null
	for item: BallDefinition in ball_manager.items:
		if item.key == ball_key or BallKey.is_instance(item.key, ball_key):
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

	return rectangle.get_rect().has_point(collision_shape.to_local(world_position))


func _get_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null
