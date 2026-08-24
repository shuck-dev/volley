class_name ShopSoulMote
extends SoulMote

## Souls motes for the shop purchase path.

## Emitted on reaching its destination.
signal landed(soul_value: int)

## Speed the mote travels at.
@export var speed := 1200.0

## What angle the mote launches at.
@export var launch_spread_degrees := 45.0

var _destination := Vector2.ZERO


## Sends the mote to a vector.
func fly_to(destination: Vector2) -> void:
	_destination = destination

	_launch()


func _launch() -> void:
	var toward: Vector2 = (_destination - global_position).normalized()
	var spread := deg_to_rad(launch_spread_degrees)

	_heading = toward.rotated(randf_range(-spread, spread))


func _fly(delta: float) -> void:
	var step: float = speed * delta

	_steer_toward(_destination, delta, speed)

	global_position += _heading * step

	if global_position.distance_to(_destination) <= step:
		landed.emit(soul_value)
		queue_free()
