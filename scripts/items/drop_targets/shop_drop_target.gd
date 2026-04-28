class_name ShopDropTarget
extends DropTarget

## Shop target: cancels a shop-origin gesture back into the shop slot.
##
## Pre-SH-287 the shop owned its own drag controller (`scripts/shop/shop_item.gd`). The
## body-projection refactor unifies on a single controller; the shop registers a
## `ShopDropTarget` so that releases inside the shop area cancel back to the source slot
## with no purchase. Releases outside the shop area fall through to whichever target
## accepts (court for ball items, rack for equipment, etc.); the controller calls
## `_item_manager.take(...)` to commit the purchase before that downstream target runs.

var _shop_area: Area2D


func configure(shop_area: Area2D) -> void:
	_shop_area = shop_area


func can_accept(_item_key: String, position: Vector2, _scale_factor: float = 1.0) -> bool:
	# is_instance_valid guards against a freed Shop leaving a stale target registered (the
	# Shop also unregisters on tree_exiting; this is the belt to that suspenders).
	if not is_instance_valid(_shop_area):
		return false
	var rect: Rect2 = DropTarget.area_world_rect(_shop_area)
	if rect.size == Vector2.ZERO:
		return false
	return rect.has_point(position)


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	# No side effect on cancel-back: the gesture clears and the source slot becomes visible
	# again via the controller's finalisation hook.
	pass
