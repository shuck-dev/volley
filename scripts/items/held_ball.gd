class_name HeldBall
extends RefCounted

## The item in hand for a drag: a grab keeps only the key, so a drop spawns a fresh ball.

const COLLISION_RADIUS: float = 7.2

## Shared placement footprint; a static var stands in because consts cannot hold a Resource.
static var _collision_shape: CircleShape2D = _make_collision_shape()

var key: String

## A temporary's real Ball, or the frozen proxy standing in for a keyed item.
var _body: Node2D
var _is_temporary: bool


func _init(ball_key: String, body: Node2D, temporary: bool) -> void:
	key = ball_key
	_body = body
	_is_temporary = temporary


func is_temporary() -> bool:
	return _is_temporary


## Footprint a target uses to check the ball would fit where it is being dropped.
func collision_shape() -> Shape2D:
	return _collision_shape


func follow(position: Vector2) -> void:
	if is_instance_valid(_body):
		_body.global_position = position


## Puts the ball into play at `position`. A temporary rejoins as itself; a keyed item spawns anew.
func put_into_play(position: Vector2, velocity: Vector2) -> void:
	if _is_temporary:
		_body.global_position = position
		_body.enter_play()
		_body.linear_velocity = velocity
		return

	_discard_body()
	BallTracker.bring_into_play(key, position, velocity)


## Leaves the ball at rest in the venue, where it can be picked up again.
func release_at_rest(position: Vector2, velocity: Vector2) -> void:
	_discard_body()
	BallTracker.release_into_rest(key, position, velocity)
	BallManager.mark_loose_in_venue(key, position)


## Stows the ball as a static icon, with no body anywhere in the world.
func store() -> void:
	_discard_body()
	BallManager.clear_loose_in_venue(key)


## Destroys the ball without it landing anywhere.
func discard() -> void:
	_discard_body()


static func _make_collision_shape() -> CircleShape2D:
	var shape := CircleShape2D.new()
	shape.radius = COLLISION_RADIUS
	return shape


func _discard_body() -> void:
	if not is_instance_valid(_body):
		_body = null
		return

	if _is_temporary:
		BallTracker.free_temporary(_body)
	else:
		_body.queue_free()
	_body = null
