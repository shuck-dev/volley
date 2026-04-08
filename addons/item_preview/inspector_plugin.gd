@tool
extends EditorInspectorPlugin

const ArtEditorPropertyScript := preload("res://addons/item_preview/art_editor_property.gd")


func _can_handle(object: Object) -> bool:
	return object is ItemDefinition


func _parse_property(
	_object: Object,
	_type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	if name != "art":
		return false
	var editor_property := ArtEditorPropertyScript.new()
	add_property_editor(name, editor_property)
	return true
