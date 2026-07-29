class_name CadenceBallEffectProcessor
extends BallEffectProcessor

## Cycles ball_speed_scale between half, normal, and double on a random-length timer,
## independent of paddle hits; replaces Cadence's old StatShift-driven effect.

signal mode_shifted(mode: Mode)

enum Mode { HALF, NORMAL, DOUBLE }

const MODE_MULTIPLIER := {
	Mode.HALF: 0.5,
	Mode.NORMAL: 1.0,
	Mode.DOUBLE: 2.0,
}
## Cycle order starting from the initial mode: normal -> double -> half -> normal...
const MODE_ORDER: Array[Mode] = [Mode.NORMAL, Mode.DOUBLE, Mode.HALF]

@export var min_interval_seconds: float = 2.0
@export var max_interval_seconds: float = 5.0

var _mode: Mode = Mode.NORMAL
var _time_in_mode := 0.0
var _hold_duration := 0.0


func _ready() -> void:
	super._ready()
	_hold_duration = randf_range(min_interval_seconds, max_interval_seconds)


func process_frame(delta: float) -> void:
	_advance_mode(delta)
	super.process_frame(delta)


func refresh_scaled_speed() -> void:
	scaled_speed = ball.speed * MODE_MULTIPLIER[_mode]


func _advance_mode(delta: float) -> void:
	_time_in_mode += delta
	if _time_in_mode < _hold_duration:
		return

	var current_index: int = MODE_ORDER.find(_mode)
	_mode = MODE_ORDER[(current_index + 1) % MODE_ORDER.size()]
	_time_in_mode = 0.0
	_hold_duration = randf_range(min_interval_seconds, max_interval_seconds)
	mode_shifted.emit(_mode)
