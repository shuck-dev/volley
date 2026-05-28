## SH-413: item removal is allowed only at the equip pose, never mid-rally or in any other lull.
extends GutTest

const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")


func _make_timeout(state: TimeoutController.State) -> TimeoutController:
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	timeout._state = state
	return timeout


func test_removal_allowed_at_equip_pose() -> void:
	var timeout: TimeoutController = _make_timeout(TimeoutController.State.AT_EQUIP_POSE)

	assert_true(
		RallyGate.removal_allowed(timeout),
		"removal is permitted once the character reaches the equip pose",
	)


func test_removal_blocked_while_idle() -> void:
	var timeout: TimeoutController = _make_timeout(TimeoutController.State.IDLE)

	assert_false(
		RallyGate.removal_allowed(timeout),
		"removal stays blocked during normal idle play, the mid-rally case",
	)


func test_removal_blocked_during_walk_states() -> void:
	for state: TimeoutController.State in [
		TimeoutController.State.DESCENDING,
		TimeoutController.State.WALKING_OFF,
		TimeoutController.State.WALKING_ON,
		TimeoutController.State.ASCENDING,
	]:
		var timeout: TimeoutController = _make_timeout(state)

		assert_false(
			RallyGate.removal_allowed(timeout),
			"removal stays blocked while the character is mid-transition",
		)


func test_removal_blocked_when_timeout_controller_null() -> void:
	assert_false(
		RallyGate.removal_allowed(null),
		"a null controller must fail closed",
	)
