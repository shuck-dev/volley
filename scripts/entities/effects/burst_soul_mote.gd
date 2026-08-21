class_name BurstSoulMote
extends SoulMote

## Soul thrown out of a ball as a reward.

## Emitted on reaching its destination.
signal landed(soul_value: int)

## Speed the mote leaves at, bleeding off to BURST_END_SPEED before attraction.
const BURST_SPEED := 180.0
const BURST_END_SPEED := 20.0

## How long the mote drifts on its opening heading before it starts homing.
@export var attract_delay := 2.0

## Speed the mote travels at once it is homing.
@export var attract_speed := 500.0

var _catcher: Node2D = null
var _speed := BURST_SPEED
var _age := 0.0


func _ready() -> void:
	super()

	body_entered.connect(_on_body_entered)


## Throws the mote out along `heading` before it homes on `catcher`.
func burst_toward(catcher: Node2D, heading: Vector2) -> void:
	_catcher = catcher
	_heading = heading
	_speed = BURST_SPEED


func _fly(delta: float) -> void:
	_age += delta

	if _age >= attract_delay:
		_home(_catcher.global_position, delta)
	else:
		_float()

	global_position += _heading * _speed * delta


## Coasts to a near stop on the opening heading, holding the payout in view.
func _float() -> void:
	_speed = lerpf(BURST_SPEED, BURST_END_SPEED, _age / attract_delay)


## Turns onto `destination` and winds back up to full speed.
func _home(destination: Vector2, delta: float) -> void:
	_steer_toward(destination, delta, _speed)

	_speed = move_toward(_speed, attract_speed, attract_speed * delta)


func _on_body_entered(body: Node) -> void:
	if not (body is SoulCatcher):
		return

	landed.emit(soul_value)

	queue_free()
