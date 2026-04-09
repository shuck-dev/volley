extends Node

## Dev-time hot reload for Resource exports. Any Node in the "hot_reloadable_config"
## group gets all its Resource-typed script variables polled for file changes; when
## a watched file is modified, the property is re-assigned from a fresh load and the
## node's `on_config_reloaded()` method is called if present.

const POLL_INTERVAL: float = 0.25
const GROUP_NAME: StringName = &"hot_reloadable_config"

var _watches: Dictionary = {}
var _poll_accum: float = 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		return
	get_tree().node_added.connect(_on_node_added)
	for node: Node in get_tree().get_nodes_in_group(GROUP_NAME):
		_register_node(node)


func _process(delta: float) -> void:
	if not OS.is_debug_build() or _watches.is_empty():
		return
	_poll_accum += delta
	if _poll_accum < POLL_INTERVAL:
		return
	_poll_accum = 0.0
	_check_all_watches()


func _check_all_watches() -> void:
	for path: String in _watches.keys():
		var entry: Dictionary = _watches[path]
		var new_mtime: int = _read_mtime(path)
		if new_mtime == 0 or new_mtime == entry.mtime:
			continue
		entry.mtime = new_mtime
		var reloaded: Resource = ResourceLoader.load(
			path, "", ResourceLoader.CACHE_MODE_REPLACE
		)
		for binding: Dictionary in entry.bindings:
			var node: Node = binding.node_ref.get_ref()
			if node == null:
				continue
			node.set(binding.property, reloaded)
			if node.has_method("on_config_reloaded"):
				node.call("on_config_reloaded")


func _on_node_added(node: Node) -> void:
	if not node.is_in_group(GROUP_NAME):
		return
	_register_node(node)


func _register_node(node: Node) -> void:
	for property: Dictionary in node.get_property_list():
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var value: Variant = node.get(property.name)
		if not (value is Resource):
			continue
		var resource: Resource = value
		if resource.resource_path == "":
			continue
		_add_watch(resource.resource_path, node, property.name)
	node.tree_exiting.connect(_on_node_exiting.bind(node))


func _add_watch(path: String, node: Node, property: String) -> void:
	if not _watches.has(path):
		_watches[path] = {
			"mtime": _read_mtime(path),
			"bindings": [],
		}
	_watches[path].bindings.append({
		"node_ref": weakref(node),
		"property": property,
	})


func _on_node_exiting(node: Node) -> void:
	for path: String in _watches:
		var entry: Dictionary = _watches[path]
		entry.bindings = entry.bindings.filter(
			func(binding: Dictionary) -> bool:
				var referenced: Node = binding.node_ref.get_ref()
				return referenced != null and referenced != node
		)


func _read_mtime(path: String) -> int:
	return FileAccess.get_modified_time(ProjectSettings.globalize_path(path))
