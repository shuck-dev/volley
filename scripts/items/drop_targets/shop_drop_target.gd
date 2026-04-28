class_name ShopDropTarget
extends DropTarget

## Releases inside the shop area cancel the gesture back to the source slot with no purchase.

var _shop_area: Area2D


func configure(shop_area: Area2D) -> void:
	_shop_area = shop_area


func can_accept(_item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	# Belt to the Shop's tree_exiting unregister suspenders.
	if not is_instance_valid(_shop_area):
		return false
	var rect: Rect2 = DropTarget.area_world_rect(_shop_area)
	if rect.size == Vector2.ZERO:
		return false
	return rect.has_point(position)


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	# Cancel-back has no side effect; the controller's finalisation hook restores the source slot.
	pass
