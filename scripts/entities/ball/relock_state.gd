class_name BallRelockState
extends RefCounted

var entry_speed: float = 0.0
var initialised: bool = false
var _remaining: float = 0.0
var _from_speed: float = 0.0


func reset() -> void:
	entry_speed = 0.0
	initialised = false
	_remaining = 0.0
	_from_speed = 0.0


func enter_arc(current_speed: float) -> void:
	if not initialised:
		entry_speed = current_speed
		initialised = true


func track_speed_change(new_speed: float) -> void:
	entry_speed = new_speed
	initialised = true


# Returns true when caller should snap speed to entry_speed; false when no action or ramping.
func enter_normal(velocity_length: float, ramp_seconds: float) -> bool:
	_remaining = 0.0
	if not initialised:
		return false
	if ramp_seconds > 0.0:
		_remaining = ramp_seconds
		_from_speed = velocity_length
		return false
	return true


func is_ramping() -> bool:
	return _remaining > 0.0


func advance_ramp(delta: float, ramp_seconds: float) -> float:
	_remaining = maxf(_remaining - delta, 0.0)
	var progress: float = 1.0
	if ramp_seconds > 0.0:
		progress = clampf(1.0 - (_remaining / ramp_seconds), 0.0, 1.0)
	return lerpf(_from_speed, entry_speed, progress)
