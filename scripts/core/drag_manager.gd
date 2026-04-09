extends Node

## All drag previews route through show_preview; set_drag_preview clips to source Viewport.

@export var preview_layer_index: int = 100

var _layer: CanvasLayer
var _preview: Control


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DragPreviewLayer"
	_layer.layer = preview_layer_index
	add_child(_layer)


## Shows a drag preview Control above all SubViewports. Replaces any current preview.
func show_preview(preview: Control) -> void:
	hide_preview()
	_preview = preview
	_layer.add_child(_preview)
	_update_preview_position()


func hide_preview() -> void:
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null


func _input(event: InputEvent) -> void:
	if _preview == null or not (event is InputEventMouseMotion):
		return
	_preview.global_position = event.position


func _update_preview_position() -> void:
	if _preview == null:
		return
	_preview.global_position = get_viewport().get_mouse_position()
