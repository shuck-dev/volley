extends GutTest

var _tracker: HitTracker


func before_each() -> void:
	_tracker = HitTracker.new()


# --- try_hit ---
func test_try_hit_returns_true_when_ready() -> void:
	assert_true(_tracker.try_hit())


func test_try_hit_increments_streak() -> void:
	_tracker.try_hit()
	assert_eq(_tracker.streak, 1)


func test_try_hit_returns_false_during_cooldown() -> void:
	_tracker.try_hit()
	assert_false(_tracker.try_hit())


func test_try_hit_during_cooldown_does_not_increment_streak() -> void:
	_tracker.try_hit()
	_tracker.try_hit()
	assert_eq(_tracker.streak, 1)


func test_try_hit_allowed_after_cooldown_expires() -> void:
	_tracker.try_hit()
	_tracker.process(HitTracker.COOLDOWN)
	assert_true(_tracker.try_hit())


func test_streak_increments_after_cooldown_expires() -> void:
	_tracker.try_hit()
	_tracker.process(HitTracker.COOLDOWN)
	_tracker.try_hit()
	assert_eq(_tracker.streak, 2)


# --- reset ---
func test_reset_clears_streak() -> void:
	_tracker.try_hit()
	_tracker.reset()
	assert_eq(_tracker.streak, 0)


func test_hit_allowed_immediately_after_reset() -> void:
	_tracker.try_hit()
	_tracker.reset()
	assert_true(_tracker.try_hit())
