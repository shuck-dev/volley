class_name RallyGate

## Rally-in-progress gate: timeout idle AND at least one ball in PLAY.
## Blocks item removal mid-rally per #692; symmetric counterpart to the equip window.

const TIMEOUT_GROUP: StringName = &"rally_gate_timeout"
const RECONCILER_GROUP: StringName = &"rally_gate_reconciler"


static func is_rally_in_progress(
	timeout_controller: TimeoutController, reconciler: BallReconciler
) -> bool:
	if timeout_controller == null or reconciler == null:
		return false
	if timeout_controller.is_active():
		return false
	return reconciler.has_ball_in_play()


## Tree-walked variant for callers without injected refs (dev panels, deep HUD).
static func is_rally_in_progress_in_tree(tree: SceneTree) -> bool:
	if tree == null:
		return false
	var timeout_controller: TimeoutController = tree.get_first_node_in_group(TIMEOUT_GROUP)
	var reconciler: BallReconciler = tree.get_first_node_in_group(RECONCILER_GROUP)
	return is_rally_in_progress(timeout_controller, reconciler)
