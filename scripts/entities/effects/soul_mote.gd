class_name SoulMote
extends Area2D

## Color per denomination.
const DENOMINATION_COLORS: Dictionary[int, Color] = {
	100: Color(0.6, 0.2, 0.9),
	1: Color(1.0, 1.0, 1.0),
}

## Initial speed the mote carries from its burst heading, decelerates toward BURST_END_SPEED.
const BURST_SPEED := 180.0
const BURST_END_SPEED := 20.0

## How long the mote flies on its burst heading before becoming attracted.
const ATTRACT_DELAY := 2.0

## How many positions the trail keeps before destroying the oldest.
const TRAIL_LENGTH := 12

## How fast the mote's heading turns toward the player.
@export var turn_degrees_per_second := 240.0

## Speed the mote travels at once it's homing toward the player.
@export var attract_speed := 500.0

@export var sprite: Sprite2D
@export var glow: Sprite2D
@export var trail: Line2D

## Soul carried by the mote
var soul_value := 0

## Direction the mote starts.
var initial_heading := Vector2.RIGHT

var _heading: Vector2
var _speed := BURST_SPEED
var _age := 0.0


func _ready() -> void:
	_heading = initial_heading
	body_entered.connect(_on_body_entered)

	var color: Color = DENOMINATION_COLORS.get(soul_value, Color.WHITE)
	sprite.modulate = color
	glow.modulate = color
	trail.default_color = color


func _physics_process(delta: float) -> void:
	_age += delta

	if _age >= ATTRACT_DELAY:
		_steer(delta)
		_speed = move_toward(_speed, attract_speed, attract_speed * delta)
	else:
		var deceleration_fraction: float = _age / ATTRACT_DELAY
		_speed = lerpf(BURST_SPEED, BURST_END_SPEED, deceleration_fraction)

	global_position += _heading * _speed * delta

	_update_trail()


func _update_trail() -> void:
	trail.add_point(global_position)

	while trail.get_point_count() > TRAIL_LENGTH:
		trail.remove_point(0)


func _steer(delta: float) -> void:
	var paddle_position: Variant = BallTracker.get_player_paddle_position()

	if paddle_position == null:
		return

	var target_direction: Vector2 = (paddle_position - global_position).normalized()

	if target_direction == Vector2.ZERO:
		return

	var max_turn_radians := deg_to_rad(turn_degrees_per_second) * delta
	var turn_radians := clampf(
		_heading.angle_to(target_direction), -max_turn_radians, max_turn_radians
	)

	_heading = _heading.rotated(turn_radians)


func _on_body_entered(body: Node) -> void:
	if not (body is Paddle):
		return

	BallManager.add_soul(soul_value)

	queue_free()
