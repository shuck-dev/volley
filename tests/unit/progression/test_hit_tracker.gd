extends GutTest

var _tracker: HitTracker


func before_each() -> void:
	_tracker = HitTracker.new()
	add_child_autofree(_tracker)


# --- try_hit ---
func test_try_hit_returns_true_when_ready() -> void:
	assert_true(_tracker.try_hit())


func test_try_hit_returns_false_during_cooldown() -> void:
	_tracker.try_hit()
	assert_false(_tracker.try_hit())


func test_try_hit_allowed_after_cooldown_expires() -> void:
	_tracker.try_hit()
	_tracker._process(HitTracker.COOLDOWN)
	assert_true(_tracker.try_hit())


# --- reset ---
func test_hit_allowed_immediately_after_reset() -> void:
	_tracker.try_hit()
	_tracker.reset()
	assert_true(_tracker.try_hit())
