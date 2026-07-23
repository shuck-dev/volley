class_name StatShift
extends RefCounted

## Discrete half/normal/double multiplier on a stat, holding each mode for a
## random duration before shifting to the next.

signal shifted(mode: Mode)

enum Mode { HALF, NORMAL, DOUBLE }

const MODE_MULTIPLIER := {
	Mode.HALF: 0.5,
	Mode.NORMAL: 1.0,
	Mode.DOUBLE: 2.0,
}
const MODE_ORDER: Array[Mode] = [Mode.HALF, Mode.NORMAL, Mode.DOUBLE]

var source_key: String
var stat_key: StringName
var range_stat_key: StringName
var min_interval: float
var max_interval: float
var _mode: Mode = Mode.NORMAL
var _time_in_mode := 0.0
var _hold_duration := 0.0
var _range_value := 1.0


func start() -> void:
	_hold_duration = randf_range(min_interval, max_interval)


func advance(delta: float) -> void:
	_time_in_mode += delta
	if _time_in_mode >= _hold_duration:
		_shift_mode()


func set_range_value(value: float) -> void:
	_range_value = value


func get_offset() -> float:
	return (MODE_MULTIPLIER[_mode] - 1.0) * _range_value


func _shift_mode() -> void:
	var current_index: int = MODE_ORDER.find(_mode)
	_mode = MODE_ORDER[(current_index + 1) % MODE_ORDER.size()]
	_time_in_mode = 0.0
	_hold_duration = randf_range(min_interval, max_interval)
	shifted.emit(_mode)
