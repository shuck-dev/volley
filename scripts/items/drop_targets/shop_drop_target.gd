class_name ShopDropTarget
extends DropTarget


func _ready() -> void:
	add_to_group(&"drop_targets")


func can_accept(_item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	var rect: Rect2 = area_world_rect()
	if rect.size == Vector2.ZERO:
		return false
	return rect.has_point(position)


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	# Cancel-back has no side effect; the controller's finalisation hook restores the source slot.
	pass
