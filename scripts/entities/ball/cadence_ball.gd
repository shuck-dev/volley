class_name CadenceBall
extends Ball

## Fires on every speed-mode shift so the particle cue and dev tooling can react.
signal mode_shifted(mode: Mode)

enum Mode { HALF, NORMAL, DOUBLE }

const MODE_MULTIPLIER := {
	Mode.HALF: 0.5,
	Mode.NORMAL: 1.0,
	Mode.DOUBLE: 2.0,
}
## Cycle order starting from the initial mode: normal -> double -> half -> normal...
const MODE_ORDER: Array[Mode] = [Mode.NORMAL, Mode.DOUBLE, Mode.HALF]

## Particle cue fired on every speed-mode shift; authored in the inherited scene.
@export var shift_cue: CPUParticles2D
@export var min_interval_seconds: float = 2.0
@export var max_interval_seconds: float = 5.0

var _mode: Mode = Mode.NORMAL
var _time_in_mode := 0.0
var _hold_duration := 0.0


func _ready() -> void:
	super._ready()
	_hold_duration = randf_range(min_interval_seconds, max_interval_seconds)


func _physics_process(delta: float) -> void:
	if linear_velocity == Vector2.ZERO:
		return

	_advance_mode(delta)
	super._physics_process(delta)


func refresh_scaled_speed() -> void:
	scaled_speed = speed * MODE_MULTIPLIER[_mode]


func _advance_mode(delta: float) -> void:
	_time_in_mode += delta
	if _time_in_mode < _hold_duration:
		return

	var current_index: int = MODE_ORDER.find(_mode)
	_mode = MODE_ORDER[(current_index + 1) % MODE_ORDER.size()]
	_time_in_mode = 0.0
	_hold_duration = randf_range(min_interval_seconds, max_interval_seconds)
	mode_shifted.emit(_mode)
	_on_mode_shifted(_mode)


func _on_mode_shifted(_mode_value: Mode) -> void:
	if shift_cue == null:
		return
	shift_cue.restart()
	shift_cue.emitting = true
