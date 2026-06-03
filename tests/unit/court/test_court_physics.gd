extends GutTest

var _physics: CourtPhysics


func before_each() -> void:
	_physics = CourtPhysics.new()
	_physics.arc_gravity = 600.0
	_physics.arc_height_max = 220.0


# The apex an entry would reach under a given downward acceleration: classic v^2 / 2a.
func _apex_for(entry_speed_up: float, accel: float) -> float:
	return (entry_speed_up * entry_speed_up) / (2.0 * accel)


func test_gentle_entry_arcs_below_the_ceiling() -> void:
	var accel: float = _physics.arc_acceleration(300.0)
	assert_almost_eq(accel, 600.0, 0.001, "below the ceiling the bend stays at the tuned gravity")
	assert_almost_eq(_apex_for(300.0, accel), 75.0, 0.5, "apex emerges from the entry speed")


func test_faster_entry_arcs_higher() -> void:
	var slow_apex: float = _apex_for(200.0, _physics.arc_acceleration(200.0))
	var fast_apex: float = _apex_for(400.0, _physics.arc_acceleration(400.0))
	assert_gt(fast_apex, slow_apex, "a faster upward entry peaks higher")


func test_steep_entry_is_capped_at_the_ceiling() -> void:
	# vy=600 would peak at 300px under the tuned gravity; the ceiling is 220.
	var accel: float = _physics.arc_acceleration(600.0)
	assert_gt(accel, 600.0, "the bend stiffens past the ceiling")
	assert_almost_eq(_apex_for(600.0, accel), 220.0, 0.5, "the peak lands exactly at the ceiling")


func test_no_upward_motion_does_not_arc() -> void:
	assert_eq(_physics.arc_acceleration(0.0), 0.0, "a flat entry has no arc")
	assert_eq(_physics.arc_acceleration(-50.0), 0.0, "a downward entry has no arc")
