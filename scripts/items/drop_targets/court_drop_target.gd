class_name CourtDropTarget
extends DropTarget

## The playfield: a drop here puts the ball into play, if it fits.


func can_accept(item: HeldBall, world_position: Vector2, _screen_position: Vector2) -> bool:
	if not contains_point(world_position):
		return false
	return _projection_clear(world_position, item.collision_shape())


func accept(item: HeldBall, world_position: Vector2, gesture_velocity: Vector2) -> bool:
	item.put_into_play(world_position, gesture_velocity)
	return true
