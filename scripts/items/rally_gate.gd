class_name RallyGate

## Rally-in-progress gate: timeout idle AND at least one ball in PLAY.
## Blocks equipment interaction mid-rally per #691/#692.


static func is_rally_in_progress(
	timeout_controller: TimeoutController, reconciler: BallReconciler
) -> bool:
	if timeout_controller == null or reconciler == null:
		return false
	if timeout_controller.is_active():
		return false
	return reconciler.has_ball_in_play()
