extends Label

@export var court: Court


func _ready() -> void:
	var handler: TierRewardHandler = _find_handler()

	if handler != null:
		_refresh(handler)
	else:
		get_tree().node_added.connect(_on_node_added_waiting)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree().node_added.is_connected(_on_node_added_waiting):
		get_tree().node_added.disconnect(_on_node_added_waiting)


func _on_node_added_waiting(node: Node) -> void:
	var handler := node as TierRewardHandler

	if handler == null:
		return

	get_tree().node_added.disconnect(_on_node_added_waiting)
	_refresh(handler)


func _find_handler() -> TierRewardHandler:
	return get_tree().get_first_node_in_group(&"tier_reward_handlers") as TierRewardHandler


func _refresh(handler: TierRewardHandler) -> void:
	text = "x%d soul/tier" % handler.soul_per_tier_base
