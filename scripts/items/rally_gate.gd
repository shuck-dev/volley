class_name RallyGate


## True when a rally is in progress: timeout idle AND a ball in PLAY.
static func is_rally_in_progress(timeout_active: bool, ball_in_play: bool) -> bool:
	return not timeout_active and ball_in_play


## Same predicate, but reads from injected refs and null-guards. False when either is null.
static func from_refs(timeout_controller: TimeoutController, reconciler: BallReconciler) -> bool:
	if timeout_controller == null or reconciler == null:
		return false
	return is_rally_in_progress(timeout_controller.is_active(), reconciler.has_ball_in_play())


## True only at the equip pose; the affirmative gate equip drops use, mirrored for removal.
static func removal_allowed(timeout_controller: TimeoutController) -> bool:
	if timeout_controller == null:
		return false
	return timeout_controller.get_state() == TimeoutController.State.AT_EQUIP_POSE
