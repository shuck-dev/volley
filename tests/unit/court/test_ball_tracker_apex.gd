extends GutTest

# BallTracker pushes the per-Court apex tuning down to every attached ball,
# both newly-attached and balls already tracked when configure_apex is called.

const BallScript: GDScript = preload("res://scripts/entities/ball.gd")
const TrackerScript: GDScript = preload("res://scripts/court/ball_tracker.gd")

var _tracker: BallTracker


func before_each() -> void:
	_tracker = TrackerScript.new()
	add_child_autofree(_tracker)


func _make_ball() -> Ball:
	var ball: Ball = BallScript.new()
	ball.apex_bound_y = 0.0
	ball.apex_gravity_scale = 0.0
	add_child_autofree(ball)
	return ball


func test_attach_after_configure_apex_propagates_values() -> void:
	_tracker.configure_apex(-250.0, 2.0)
	var ball: Ball = _make_ball()
	_tracker.attach(ball)
	assert_almost_eq(ball.apex_bound_y, -250.0, 0.001)
	assert_almost_eq(ball.apex_gravity_scale, 2.0, 0.001)


func test_configure_apex_updates_already_tracked_balls() -> void:
	var ball: Ball = _make_ball()
	_tracker.attach(ball)
	_tracker.configure_apex(-400.0, 0.75)
	assert_almost_eq(ball.apex_bound_y, -400.0, 0.001)
	assert_almost_eq(ball.apex_gravity_scale, 0.75, 0.001)


func test_attach_without_configure_apex_uses_tracker_defaults() -> void:
	# Tracker's defaults match ApexDefaults; production wires Court before attach so this is a safety-net.
	var ball: Ball = _make_ball()
	_tracker.attach(ball)
	assert_almost_eq(ball.apex_bound_y, ApexDefaults.BOUND_Y, 0.001)
	assert_almost_eq(ball.apex_gravity_scale, ApexDefaults.GRAVITY_SCALE, 0.001)
