extends GutTest

var _relock: BallRelockState


func before_each() -> void:
	_relock = BallRelockState.new()


func test_enter_arc_first_time_records_entry_speed() -> void:
	_relock.enter_arc(500.0)
	assert_almost_eq(_relock.entry_speed, 500.0, 0.01)
	assert_true(_relock.initialised)


func test_enter_arc_does_not_overwrite_subsequent_calls() -> void:
	_relock.enter_arc(500.0)
	_relock.enter_arc(800.0)
	assert_almost_eq(_relock.entry_speed, 500.0, 0.01, "register persists; first value remains")


func test_track_speed_change_updates_entry_speed() -> void:
	_relock.enter_arc(500.0)
	_relock.track_speed_change(620.0)
	assert_almost_eq(_relock.entry_speed, 620.0, 0.01)


func test_track_speed_change_initialises_when_uncalled() -> void:
	_relock.track_speed_change(450.0)
	assert_true(_relock.initialised)
	assert_almost_eq(_relock.entry_speed, 450.0, 0.01)


func test_enter_normal_without_init_returns_false() -> void:
	var should_snap: bool = _relock.enter_normal(300.0, 0.0)
	assert_false(should_snap)
	assert_false(_relock.is_ramping())


func test_enter_normal_zero_ramp_snaps() -> void:
	_relock.enter_arc(700.0)
	var should_snap: bool = _relock.enter_normal(400.0, 0.0)
	assert_true(should_snap, "zero ramp signals snap to entry_speed")
	assert_false(_relock.is_ramping())


func test_enter_normal_positive_ramp_starts_ramping() -> void:
	_relock.enter_arc(700.0)
	var should_snap: bool = _relock.enter_normal(400.0, 0.12)
	assert_false(should_snap)
	assert_true(_relock.is_ramping())


func test_advance_ramp_progresses_from_velocity_to_entry_speed() -> void:
	_relock.enter_arc(700.0)
	_relock.enter_normal(400.0, 0.12)
	var mid: float = _relock.advance_ramp(0.06, 0.12)
	assert_almost_eq(mid, 550.0, 5.0, "halfway lerps between 400 and 700")
	var done: float = _relock.advance_ramp(0.06, 0.12)
	assert_almost_eq(done, 700.0, 0.5, "ramp lands at entry_speed")
	assert_false(_relock.is_ramping())


func test_reset_clears_state() -> void:
	_relock.enter_arc(700.0)
	_relock.enter_normal(400.0, 0.12)
	_relock.reset()
	assert_false(_relock.initialised)
	assert_false(_relock.is_ramping())
	assert_almost_eq(_relock.entry_speed, 0.0, 0.01)
