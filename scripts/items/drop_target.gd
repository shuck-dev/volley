class_name DropTarget
extends RefCounted

## Abstract drop target consulted by BallDragController each physics frame.
##
## SH-287 (designs/01-prototype/21-ball-dynamics.md, "Drop validation by body projection"):
## the drag controller polls every registered target on the held token's world position; the
## first target whose `can_accept` returns true takes the drop. `accept` performs the side
## effect (spawning a ball, returning to a slot, completing a purchase, etc.). Subclasses
## override both methods.


## Returns true when this target would accept `item_key` at `position` right now.
## Targets that are role-restricted (e.g. ball rack only takes ball-role items) gate here.
## Court projection runs `intersect_shape` here against the item's `at_rest_shape`.
func can_accept(_item_key: String, _position: Vector2, _scale_factor: float = 1.0) -> bool:
	return false


## Side-effect: commit the drop. Caller has already gated on `can_accept`.
func accept(_item_key: String, _position: Vector2, _gesture_velocity: Vector2) -> void:
	pass


# --- Shared helpers used by concrete targets ----------------------------------------


## Resolves an `ItemDefinition` by `key` from a manager that exposes an `items` array.
## Returns null if the manager is missing or the key is unknown.
static func get_definition(item_manager: Node, item_key: String) -> ItemDefinition:
	if item_manager == null:
		return null
	for item: ItemDefinition in item_manager.items:
		if item.key == item_key:
			return item
	return null


## Clamps `world_position` into `bounds`. Zero-sized bounds pass through unchanged so an
## un-configured court does not collapse releases to the origin.
static func clamp_to_rect(world_position: Vector2, bounds: Rect2) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return world_position
	return Vector2(
		clampf(world_position.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clampf(world_position.y, bounds.position.y, bounds.position.y + bounds.size.y),
	)


## Builds a world-space `Rect2` from an `Area2D`'s first `RectangleShape2D` child.
## Returns an empty `Rect2()` when the area is missing/freed or has no rectangular collider.
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
