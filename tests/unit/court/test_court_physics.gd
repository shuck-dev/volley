extends GutTest

var _physics: CourtPhysics


func before_each() -> void:
	_physics = CourtPhysics.new()
	_physics.arc_bend = 600.0
	_physics.arc_height_max = 220.0


func test_apex_below_ceiling_is_unclamped() -> void:
	assert_almost_eq(_physics.arc_acceleration(300.0), 600.0, 0.001)


func test_apex_above_ceiling_is_clamped() -> void:
	assert_gt(_physics.arc_acceleration(600.0), 600.0)


func test_clamped_apex_lands_at_ceiling() -> void:
	var accel: float = _physics.arc_acceleration(600.0)
	var apex: float = (600.0 * 600.0) / (2.0 * accel)
	assert_almost_eq(apex, 220.0, 0.5)


func test_downward_entry_still_bends_down() -> void:
	assert_almost_eq(_physics.arc_acceleration(0.0), 600.0, 0.001)
	assert_almost_eq(_physics.arc_acceleration(-50.0), 600.0, 0.001)


func test_zero_bend_returns_zero() -> void:
	_physics.arc_bend = 0.0
	assert_eq(_physics.arc_acceleration(300.0), 0.0)
