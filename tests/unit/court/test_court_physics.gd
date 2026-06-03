extends GutTest

var _physics: CourtPhysics


func before_each() -> void:
	_physics = CourtPhysics.new()
	_physics.arc_gravity = 600.0
	_physics.arc_height_max = 220.0


func test_gentle_entry_uses_the_tuned_gravity() -> void:
	assert_almost_eq(
		_physics.arc_acceleration(300.0),
		600.0,
		0.001,
		"below the ceiling the bend is the tuned gravity"
	)


func test_steep_entry_stiffens_the_bend() -> void:
	assert_gt(
		_physics.arc_acceleration(600.0),
		600.0,
		"a steep entry bends harder than the tuned gravity to cap the apex"
	)


func test_stiffened_bend_caps_the_apex_at_the_ceiling() -> void:
	var steep: float = _physics.arc_acceleration(600.0)
	var apex: float = (600.0 * 600.0) / (2.0 * steep)
	assert_almost_eq(
		apex, 220.0, 0.5, "the capped bend lands the peak at the ceiling, not above it"
	)


func test_no_upward_motion_does_not_arc() -> void:
	assert_eq(_physics.arc_acceleration(0.0), 0.0, "a flat entry has no arc")
	assert_eq(_physics.arc_acceleration(-50.0), 0.0, "a downward entry has no arc")


func test_zero_gravity_is_guarded() -> void:
	_physics.arc_gravity = 0.0
	assert_eq(
		_physics.arc_acceleration(300.0),
		0.0,
		"a misconfigured zero gravity does not divide by zero"
	)
