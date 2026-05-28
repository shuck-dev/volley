class_name RallyGate


## True only at the equip pose; the affirmative gate equip drops use, mirrored for removal.
static func removal_allowed(timeout_controller: TimeoutController) -> bool:
	if timeout_controller == null:
		return false
	return timeout_controller.get_state() == TimeoutController.State.AT_EQUIP_POSE
