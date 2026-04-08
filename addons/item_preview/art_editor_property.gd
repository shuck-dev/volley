@tool
extends EditorProperty

const ArtPreviewScript := preload("res://addons/item_preview/art_preview.gd")

var _picker: EditorResourcePicker
var _preview: Control
var _updating: bool = false


func _init() -> void:
	_picker = EditorResourcePicker.new()
	_picker.base_type = "PackedScene"
	_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker.resource_changed.connect(_on_resource_changed)
	add_child(_picker)
	add_focusable(_picker)

	_preview = ArtPreviewScript.new()
	add_child(_preview)
	set_bottom_editor(_preview)


func _update_property() -> void:
	var current_value: Variant = get_edited_object().get(get_edited_property())
	_updating = true
	_picker.edited_resource = current_value
	_updating = false
	_refresh_preview(current_value)


func _on_resource_changed(new_resource: Resource) -> void:
	if _updating:
		return
	emit_changed(get_edited_property(), new_resource)
	_refresh_preview(new_resource)


func _refresh_preview(scene: Variant) -> void:
	_preview.clear_scene()
	if scene is PackedScene:
		_preview.show_scene(scene as PackedScene)
