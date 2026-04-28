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
	if _shop_area == null:
		return false
	return _position_inside_area(position)


func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	# No side effect on cancel-back: the gesture clears and the source slot becomes visible
	# again via the controller's finalisation hook.
	pass


func _position_inside_area(world_position: Vector2) -> bool:
	var shape_owner: CollisionShape2D = null
	for child in _shop_area.get_children():
		if child is CollisionShape2D:
			shape_owner = child
			break
	if shape_owner == null:
		return false
	var rectangle: RectangleShape2D = shape_owner.shape as RectangleShape2D
	if rectangle == null:
		return false
	var half_extents: Vector2 = rectangle.size * 0.5
	var center: Vector2 = _shop_area.global_position + shape_owner.position
	return Rect2(center - half_extents, rectangle.size).has_point(world_position)
