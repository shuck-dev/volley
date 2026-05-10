extends GutTest

var _tracker: BallSpeedEmitTracker


func before_each() -> void:
	_tracker = BallSpeedEmitTracker.new()


func test_first_call_emits_when_speed_above_threshold() -> void:
	assert_true(_tracker.should_emit_speed(50.0, 0.0, 0.0))


func test_no_emit_when_recorded_values_unchanged() -> void:
	_tracker.record_speed(100.0, 10.0, 200.0)
	assert_false(_tracker.should_emit_speed(100.0, 10.0, 200.0))


func test_emit_when_speed_delta_meets_threshold() -> void:
	_tracker.record_speed(100.0, 10.0, 200.0)
	assert_true(_tracker.should_emit_speed(110.0, 10.0, 200.0))


func test_no_emit_when_speed_delta_below_threshold() -> void:
	_tracker.record_speed(100.0, 10.0, 200.0)
	assert_false(_tracker.should_emit_speed(105.0, 10.0, 200.0))


func test_emit_when_min_changes_even_if_speed_static() -> void:
	_tracker.record_speed(100.0, 10.0, 200.0)
	assert_true(_tracker.should_emit_speed(100.0, 20.0, 200.0))


func test_emit_when_max_changes_even_if_speed_static() -> void:
	_tracker.record_speed(100.0, 10.0, 200.0)
	assert_true(_tracker.should_emit_speed(100.0, 10.0, 250.0))


func test_consume_max_change_fires_once_per_transition() -> void:
	assert_true(_tracker.consume_max_change(true), "first transition to max fires")
	assert_false(_tracker.consume_max_change(true), "stable at max does not fire")
	assert_true(_tracker.consume_max_change(false), "transition off max fires")
	assert_false(_tracker.consume_max_change(false), "stable off max does not fire")
