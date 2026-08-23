class_name SoulMote
extends Area2D

## A single soul in flight. Subclasses own traveling behaviour.
## Owns appearance and turning radius.

## Color per denomination, so a mote's worth reads at a glance.
const DENOMINATION_COLORS: Dictionary[int, Color] = {
	1: Color(1.0, 1.0, 1.0),
	10: Color(0.45, 0.75, 1.0),
	100: Color(0.6, 0.2, 0.9),
	1000: Color(1.0, 0.65, 0.15),
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
	var color: Color = _denomination_color()

	sprite.modulate = color
	glow.modulate = color

	# The trail's gradient wins over default_color, so tint it rather than set it.
	trail.modulate = color


## The colour of the largest denomination this mote covers.
func _denomination_color() -> Color:
	var color: Color = DENOMINATION_COLORS[1]

	for denomination: int in DENOMINATION_COLORS:
		if soul_value >= denomination:
			color = DENOMINATION_COLORS[denomination]

	return color


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


## Turns the heading toward `destination`, capped by a turn rate that lifts up close.
func _steer_toward(destination: Vector2, delta: float, speed: float) -> void:
	var to_destination: Vector2 = destination - global_position
	var target_direction: Vector2 = to_destination.normalized()

	if target_direction == Vector2.ZERO:
		return

	var turn_degrees: float = turn_degrees_per_second
	var turning_radius: float = speed / deg_to_rad(turn_degrees_per_second)
	var distance: float = to_destination.length()

	# A destination inside the turning circle cannot be reached, only orbited.
	if distance < turning_radius:
		turn_degrees *= turning_radius / maxf(distance, 1.0)

	var max_turn_radians := deg_to_rad(turn_degrees) * delta
	var turn_radians := clampf(
		_heading.angle_to(target_direction), -max_turn_radians, max_turn_radians
	)

	_heading = _heading.rotated(turn_radians)
