class_name SoulMote
extends Area2D

## Emitted when the mote lands on its catcher. The spawning handler decides what arrival means.
signal arrived(soul_value: int)

## Emitted when a mote sent home clears the screen, carrying its soul back out.
signal departed(soul_value: int)

## Color per denomination.
const DENOMINATION_COLORS: Dictionary[int, Color] = {
	100: Color(0.6, 0.2, 0.9),
	1: Color(1.0, 1.0, 1.0),
}

## Initial speed the mote carries from its burst heading, decelerates toward BURST_END_SPEED.
const BURST_SPEED := 180.0
const BURST_END_SPEED := 20.0

## How many positions the trail keeps before destroying the oldest.
const TRAIL_LENGTH := 12

## How long the mote drifts on its initial heading before it starts homing.
@export var attract_delay := 2.0

## Whether the mote drifts and slows before homing. Off flies straight in from the start.
@export var drifts_before_homing := true

## How fast the mote's heading turns toward the player.
@export var turn_degrees_per_second := 240.0

## Speed the mote travels at once it's homing toward its target.
@export var attract_speed := 500.0

@export var sprite: Sprite2D
@export var glow: Sprite2D
@export var trail: Line2D

## Soul carried by the mote
var soul_value := 0

## Direction the mote starts.
var initial_heading := Vector2.RIGHT

## Node the mote steers toward; re-read every frame so a moving catcher stays tracked.
var target: Node2D = null

var _heading: Vector2
var _speed := BURST_SPEED
var _exit_position := Vector2.ZERO
var _age := 0.0
var _going_home := false


func _ready() -> void:
	_heading = initial_heading
	_speed = BURST_SPEED if drifts_before_homing else attract_speed
	body_entered.connect(_on_body_entered)

	var color: Color = DENOMINATION_COLORS.get(soul_value, Color.WHITE)
	sprite.modulate = color
	glow.modulate = color
	trail.default_color = color


func _physics_process(delta: float) -> void:
	_age += delta

	if _going_home:
		var step: float = attract_speed * delta

		# Fanned out of the ball, the mote curves back so it still reaches the exit.
		_steer_toward(_exit_position, delta)

		global_position += _heading * step
		_update_trail()

		# Reaching the exit point is what counts as gone, so a spawn point left on
		# screen still returns its soul rather than stranding the mote in flight.
		if global_position.distance_to(_exit_position) <= step:
			departed.emit(soul_value)
			queue_free()

		return

	if not drifts_before_homing or _age >= attract_delay:
		_steer(delta)
		_speed = move_toward(_speed, attract_speed, attract_speed * delta)
	else:
		var deceleration_fraction: float = _age / attract_delay
		_speed = lerpf(BURST_SPEED, BURST_END_SPEED, deceleration_fraction)

	global_position += _heading * _speed * delta

	_update_trail()


## Sends the mote back toward where it entered, to be freed once it clears the screen.
## `cone_radians` fans the launch heading either side of the exit, so a batch
## leaving one point spreads out before curving back together.
func send_home(exit_position: Vector2, cone_radians: float = 0.0) -> void:
	var away: Vector2 = (exit_position - global_position).normalized()

	if away == Vector2.ZERO:
		away = Vector2.UP

	target = null
	_exit_position = exit_position
	_heading = away.rotated(randf_range(-cone_radians, cone_radians) * 0.5)
	_going_home = true

	# Nothing catches a mote that is leaving, and it starts inside the catcher.
	set_deferred(&"monitoring", false)


func _update_trail() -> void:
	trail.add_point(global_position)

	while trail.get_point_count() > TRAIL_LENGTH:
		trail.remove_point(0)


func _steer(delta: float) -> void:
	if not is_instance_valid(target):
		return

	_steer_toward(target.global_position, delta)


func _steer_toward(destination: Vector2, delta: float) -> void:
	var target_direction: Vector2 = (destination - global_position).normalized()

	if target_direction == Vector2.ZERO:
		return

	var max_turn_radians := deg_to_rad(turn_degrees_per_second) * delta
	var turn_radians := clampf(
		_heading.angle_to(target_direction), -max_turn_radians, max_turn_radians
	)

	_heading = _heading.rotated(turn_radians)


func _on_body_entered(body: Node) -> void:
	# A mote on its way out starts inside the catcher it was collected by, so
	# arriving is only meaningful while it is still travelling toward one.
	if _going_home or not (body is SoulCatcher):
		return

	arrived.emit(soul_value)

	queue_free()
