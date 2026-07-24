extends GutTest

# Verifies StatShift: discrete half/normal/double shifting and randomized hold duration.


func _make_shift(min_interval: float, max_interval: float) -> StatShift:
	var shift := StatShift.new()
	shift.stat_key = &"speed"
	shift.source_key = "cadence_1"
	shift.range_stat_key = &"speed_range"
	shift.min_interval = min_interval
	shift.max_interval = max_interval
	shift.set_range_value(100.0)
	shift.start()
	return shift


func test_starts_in_normal_mode_with_zero_offset() -> void:
	var shift := _make_shift(1.0, 1.0)
	assert_eq(shift.get_offset(), 0.0)


func test_advancing_before_hold_duration_stays_in_mode() -> void:
	var shift := _make_shift(10.0, 10.0)
	shift.advance(1.0)
	assert_eq(shift.get_offset(), 0.0, "still normal; hold duration not reached")


func test_shifting_cycles_normal_double_half_back_to_normal() -> void:
	var shift := _make_shift(1.0, 1.0)
	shift.advance(1.0)
	assert_almost_eq(shift.get_offset(), 100.0, 0.0001, "normal -> double is +100% of range")
	shift.advance(1.0)
	assert_almost_eq(shift.get_offset(), -50.0, 0.0001, "double -> half is -50% of range")
	shift.advance(1.0)
	assert_eq(shift.get_offset(), 0.0, "half -> normal wraps back to zero offset")


func test_shift_emits_signal_on_transition() -> void:
	var shift := _make_shift(1.0, 1.0)
	watch_signals(shift)
	shift.advance(1.0)
	assert_signal_emitted_with_parameters(shift, "shifted", [StatShift.Mode.DOUBLE])
