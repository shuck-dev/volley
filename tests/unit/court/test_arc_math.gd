extends GutTest

const ARC_HEIGHT_MAX := 220.0


func test_apex_below_ceiling_returns_arc_bend() -> void:
	assert_almost_eq(ArcMath.arc_acceleration(300.0, ARC_HEIGHT_MAX), ArcMath.ARC_BEND, 0.001)


func test_apex_above_ceiling_exceeds_arc_bend() -> void:
	assert_gt(ArcMath.arc_acceleration(600.0, ARC_HEIGHT_MAX), ArcMath.ARC_BEND)


func test_clamped_apex_equals_height_max() -> void:
	var accel: float = ArcMath.arc_acceleration(600.0, ARC_HEIGHT_MAX)
	var apex: float = (600.0 * 600.0) / (2.0 * accel)
	assert_almost_eq(apex, ARC_HEIGHT_MAX, 0.5)


func test_downward_entry_returns_arc_bend() -> void:
	assert_almost_eq(ArcMath.arc_acceleration(0.0, ARC_HEIGHT_MAX), ArcMath.ARC_BEND, 0.001)
	assert_almost_eq(ArcMath.arc_acceleration(-50.0, ARC_HEIGHT_MAX), ArcMath.ARC_BEND, 0.001)


func test_zero_height_max_returns_zero() -> void:
	assert_eq(ArcMath.arc_acceleration(300.0, 0.0), 0.0)
