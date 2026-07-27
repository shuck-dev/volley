class_name ShopDropTarget
extends DropTarget


func can_accept(_item_key: String, world_position: Vector2, _scale_factor: float = 1.0) -> bool:
	return contains_point(world_position)


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	# Cancel-back has no side effect; the controller's finalisation hook restores the source slot.
	pass
