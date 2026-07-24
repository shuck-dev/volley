class_name ShiftRepository
extends RefCounted

## Stores active StatShift instances and answers per-stat, per-source queries over them.

var _shifts: Array[StatShift] = []


func add(shift: StatShift) -> void:
	_shifts.append(shift)


func remove_by_source(source_key: String) -> void:
	_shifts = _shifts.filter(func(shift: StatShift) -> bool: return shift.source_key != source_key)


## Shifts registered under `source_key` (e.g. a ball wiring a cue to its own shift).
func for_source(source_key: String) -> Array[StatShift]:
	return _shifts.filter(func(shift: StatShift) -> bool: return shift.source_key == source_key)


func sum_for(key: StringName, instance_key: String = "") -> float:
	var total := 0.0
	for shift in _shifts:
		if shift.stat_key != key:
			continue
		if instance_key and shift.source_key != instance_key:
			continue
		total += shift.get_offset()
	return total


func process_frame(delta: float) -> void:
	for shift in _shifts:
		shift.advance(delta)


## Recomputes every shift's cached range value against `resolve_base_stat`.
func refresh_range_values(resolve_base_stat: Callable) -> void:
	for shift in _shifts:
		if shift.range_stat_key:
			shift.set_range_value(resolve_base_stat.call(shift.range_stat_key))
