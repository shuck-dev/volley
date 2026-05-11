class_name BallSpeedEmitTracker
extends RefCounted

const SPEED_EMIT_THRESHOLD := 10.0

var _last_speed := 0.0
var _last_min := 0.0
var _last_max := 0.0
var _was_at_max := false


func should_emit_speed(speed: float, min_speed: float, max_speed: float) -> bool:
	if absf(speed - _last_speed) >= SPEED_EMIT_THRESHOLD:
		return true
	if not is_equal_approx(min_speed, _last_min):
		return true
	if not is_equal_approx(max_speed, _last_max):
		return true
	return false


func record_speed(speed: float, min_speed: float, max_speed: float) -> void:
	_last_speed = speed
	_last_min = min_speed
	_last_max = max_speed


func consume_max_change(is_at_max: bool) -> bool:
	if is_at_max == _was_at_max:
		return false
	_was_at_max = is_at_max
	return true
