extends Label

@export var court: Court


func _ready() -> void:
	var found: Node = court as Node

	if found == null:
		found = get_tree().get_first_node_in_group(&"courts")

	if found != null:
		_connect_soul_source(found)
	else:
		get_tree().node_added.connect(_on_node_added_waiting)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree().node_added.is_connected(_on_node_added_waiting):
		get_tree().node_added.disconnect(_on_node_added_waiting)


func _on_node_added_waiting(node: Node) -> void:
	if not node.is_in_group(&"courts"):
		return

	get_tree().node_added.disconnect(_on_node_added_waiting)
	_connect_soul_source(node)


func _connect_soul_source(source: Node) -> void:
	source.connect(&"soul_multiplier_changed", _on_soul_multiplier_changed)
	_refresh(roundi(ItemManager.get_stat(&"soul_multiplier")))


func _on_soul_multiplier_changed(value: int) -> void:
	_refresh(value)


func _refresh(multiplier: int) -> void:
	text = "x%d" % multiplier
