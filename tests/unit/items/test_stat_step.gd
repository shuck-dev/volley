extends GutTest

# Verifies StatStep: discrete half/normal/double stepping and randomized hold duration.


func _make_step(min_interval: float, max_interval: float) -> StatStep:
	var step := StatStep.new()
	step.stat_key = &"speed"
	step.source_key = "cadence_1"
	step.range_stat_key = &"speed_range"
	step.min_interval = min_interval
	step.max_interval = max_interval
	step.set_range_value(100.0)
	step.start()
	return step


func test_starts_in_normal_mode_with_zero_offset() -> void:
	var step := _make_step(1.0, 1.0)
	assert_eq(step.get_offset(), 0.0)


func test_advancing_past_hold_duration_steps_to_double() -> void:
	var step := _make_step(1.0, 1.0)
	step.advance(1.0)
	assert_almost_eq(step.get_offset(), 100.0, 0.0001, "normal -> double is +100% of range")


func test_stepping_cycles_double_to_half() -> void:
	var step := _make_step(1.0, 1.0)
	step.advance(1.0)
	step.advance(1.0)
	assert_almost_eq(step.get_offset(), -50.0, 0.0001, "double -> half is -50% of range")


func test_stepping_wraps_half_back_to_normal() -> void:
	var step := _make_step(1.0, 1.0)
	step.advance(1.0)
	step.advance(1.0)
	step.advance(1.0)
	assert_eq(step.get_offset(), 0.0, "half -> normal wraps back to zero offset")


func test_advancing_before_hold_duration_stays_in_mode() -> void:
	var step := _make_step(10.0, 10.0)
	step.advance(1.0)
	assert_eq(step.get_offset(), 0.0, "still normal; hold duration not reached")


func test_hold_duration_respects_configured_range() -> void:
	for i in 20:
		var step := _make_step(2.0, 5.0)
		step.advance(1.999)
		assert_eq(step.get_offset(), 0.0, "hold duration should never be below min_interval")
