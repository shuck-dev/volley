@tool
extends EditorPlugin

var _inspector: EditorInspector


func _enter_tree() -> void:
	_inspector = EditorInterface.get_inspector()
	_inspector.property_edited.connect(_on_property_edited)


func _exit_tree() -> void:
	if _inspector != null and _inspector.property_edited.is_connected(_on_property_edited):
		_inspector.property_edited.disconnect(_on_property_edited)
	_inspector = null


## Auto-saves the currently-edited resource on every inspector change so that
## the runtime hot-reload autoload picks it up without a manual Ctrl+S.
func _on_property_edited(_property: String) -> void:
	var obj: Object = _inspector.get_edited_object()
	if not (obj is Resource):
		return
	var resource: Resource = obj
	if resource.resource_path.is_empty():
		return
	ResourceSaver.save(resource)
