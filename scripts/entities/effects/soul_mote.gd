class_name SoulMote
extends Area2D

## A single soul in flight. Subclasses own traveling behaviour.
## Own appearance and turning radius.

## Color per denomination.
const DENOMINATION_COLORS: Dictionary[int, Color] = {
	100: Color(0.6, 0.2, 0.9),
	1: Color(1.0, 1.0, 1.0),
}

## How many positions the trail keeps before destroying the oldest.
const TRAIL_LENGTH := 12

## How fast the mote's heading turns toward where it is going.
@export var turn_degrees_per_second := 240.0

@export var sprite: Sprite2D
@export var glow: Sprite2D
@export var trail: Line2D

## Soul carried by the mote
var soul_value := 0

var _heading := Vector2.RIGHT


func _ready() -> void:
	var color: Color = DENOMINATION_COLORS.get(soul_value, Color.WHITE)

	sprite.modulate = color
	glow.modulate = color
	trail.default_color = color


func _physics_process(delta: float) -> void:
	_fly(delta)

	_update_trail()


## Moves the mote for this frame.
func _fly(_delta: float) -> void:
	assert(false, "SoulMote._fly() must be overridden by subclass")


func _update_trail() -> void:
	trail.add_point(global_position)

	while trail.get_point_count() > TRAIL_LENGTH:
		trail.remove_point(0)


## Turns the heading toward `destination`, capped by the mote's turn rate.
func _steer_toward(destination: Vector2, delta: float) -> void:
	var target_direction: Vector2 = (destination - global_position).normalized()

	if target_direction == Vector2.ZERO:
		return

	var max_turn_radians := deg_to_rad(turn_degrees_per_second) * delta
	var turn_radians := clampf(
		_heading.angle_to(target_direction), -max_turn_radians, max_turn_radians
	)

	_heading = _heading.rotated(turn_radians)
