class_name VenueDropTarget
extends DropTarget

## The venue floor: a drop here leaves the ball loose, to be picked up again later.


func can_accept(item: HeldBall, world_position: Vector2, _screen_position: Vector2) -> bool:
	if not contains_point(world_position):
		return false
	return _projection_clear(world_position, item.collision_shape())


## A temporary is unowned, so it cannot be left at rest; the venue takes it and frees it.
func accept(item: HeldBall, world_position: Vector2, gesture_velocity: Vector2) -> bool:
	if item.is_temporary():
		item.discard()
	else:
		item.release_at_rest(world_position, gesture_velocity)
	return true
