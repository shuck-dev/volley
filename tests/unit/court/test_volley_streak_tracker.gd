extends GutTest

const VolleyStreakTrackerScript: GDScript = preload("res://scripts/court/volley_streak_tracker.gd")

var _tracker: VolleyStreakTracker


func before_each() -> void:
	_tracker = VolleyStreakTrackerScript.new()


func test_miss_with_ball_still_in_play_does_not_reset_streak() -> void:
	_tracker.record_hit()
	_tracker.record_hit()
	watch_signals(_tracker)

	_tracker.record_miss(true)

	assert_eq(_tracker.count, 2, "streak survives a miss while another ball is still in play")
	assert_signal_not_emitted(_tracker, "volley_count_changed")


func test_miss_with_no_ball_in_play_resets_streak_to_zero() -> void:
	_tracker.record_hit()
	_tracker.record_hit()
	watch_signals(_tracker)

	_tracker.record_miss(false)

	assert_eq(_tracker.count, 0, "the last ball leaving play resets the streak")
	assert_signal_emitted_with_parameters(_tracker, "volley_count_changed", [0])
