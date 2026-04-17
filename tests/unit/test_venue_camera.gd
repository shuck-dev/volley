extends GutTest

# Verifies camera pans along x in response to camera_left/camera_right input.

const VenueCameraScene := preload("res://scripts/core/venue_camera.gd")
const LEFT_ANCHOR_X: float = -1500.0
const RIGHT_ANCHOR_X: float = 1500.0
const FAR_OUTSIDE_X: float = 9999.0
const FLOAT_TOLERANCE: float = 0.001

var _camera: VenueCamera


func before_each() -> void:
	_camera = VenueCameraScene.new()
	add_child_autofree(_camera)


func after_each() -> void:
	Input.action_release(&"camera_left")
	Input.action_release(&"camera_right")


# --- pan ---
func test_pans_right_while_camera_right_held() -> void:
	Input.action_press(&"camera_right")
	_camera._process(0.1)
	assert_gt(_camera.position.x, 0.0)


func test_pans_left_while_camera_left_held() -> void:
	Input.action_press(&"camera_left")
	_camera._process(0.1)
	assert_lt(_camera.position.x, 0.0)


func test_stays_put_without_input() -> void:
	var start_x: float = _camera.position.x
	_camera._process(0.1)
	assert_eq(_camera.position.x, start_x)


func test_higher_pan_speed_moves_further() -> void:
	var slow: VenueCamera = VenueCameraScene.new()
	slow.pan_speed = 100.0
	add_child_autofree(slow)
	var fast: VenueCamera = VenueCameraScene.new()
	fast.pan_speed = 500.0
	add_child_autofree(fast)

	Input.action_press(&"camera_right")
	slow._process(0.1)
	fast._process(0.1)

	assert_gt(fast.position.x, slow.position.x)


func test_opposing_inputs_cancel_out() -> void:
	Input.action_press(&"camera_left")
	Input.action_press(&"camera_right")
	var start_x: float = _camera.position.x
	_camera._process(0.1)
	assert_eq(_camera.position.x, start_x)


# --- clamp to anchors ---
func _make_anchor(x: float) -> Node2D:
	var anchor := Node2D.new()
	anchor.position = Vector2(x, 0.0)
	add_child_autofree(anchor)
	return anchor


func _set_bounds(left_x: float, right_x: float) -> void:
	_camera.left_anchor = _make_anchor(left_x)
	_camera.right_anchor = _make_anchor(right_x)


func _is_visible(anchor: Node2D) -> bool:
	var half_view: float = _camera.get_viewport_rect().size.x * 0.5 / _camera.zoom.x
	var distance_from_centre: float = abs(anchor.global_position.x - _camera.global_position.x)
	return distance_from_centre <= half_view + FLOAT_TOLERANCE


func _pan_until_stopped(action: StringName) -> void:
	Input.action_press(action)
	var previous: float = _camera.global_position.x
	for _i in 50:
		_camera._process(1.0)
		if is_equal_approx(_camera.global_position.x, previous):
			return
		previous = _camera.global_position.x


func test_left_anchor_stays_visible_no_matter_how_far_you_pan_left() -> void:
	_set_bounds(LEFT_ANCHOR_X, RIGHT_ANCHOR_X)
	_pan_until_stopped(&"camera_left")
	assert_true(_is_visible(_camera.left_anchor))


func test_right_anchor_stays_visible_no_matter_how_far_you_pan_right() -> void:
	_set_bounds(LEFT_ANCHOR_X, RIGHT_ANCHOR_X)
	_pan_until_stopped(&"camera_right")
	assert_true(_is_visible(_camera.right_anchor))


func test_panning_left_eventually_stops() -> void:
	_set_bounds(LEFT_ANCHOR_X, RIGHT_ANCHOR_X)
	Input.action_press(&"camera_left")
	_pan_until_stopped(&"camera_left")
	var resting_x: float = _camera.global_position.x
	_camera._process(1.0)
	assert_almost_eq(_camera.global_position.x, resting_x, FLOAT_TOLERANCE)


func test_clamp_is_noop_without_anchors() -> void:
	_camera.global_position.x = FAR_OUTSIDE_X
	_camera._process(0.0)
	assert_eq(_camera.global_position.x, FAR_OUTSIDE_X)


func test_clamp_reaches_a_stable_resting_position_when_anchors_are_swapped() -> void:
	# Swapped anchors are a misconfiguration, not a crash; the clamp should still
	# settle at a stable position rather than drifting or flying out.
	_set_bounds(RIGHT_ANCHOR_X, LEFT_ANCHOR_X)
	_camera.global_position.x = FAR_OUTSIDE_X
	_camera._process(0.0)
	var resting_x: float = _camera.global_position.x
	_camera._process(0.0)
	assert_eq(_camera.global_position.x, resting_x)
