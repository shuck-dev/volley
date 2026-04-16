extends GutTest

# Verifies camera pans along x in response to camera_left/camera_right input.

const VenueCameraScene := preload("res://scripts/core/venue_camera.gd")

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
