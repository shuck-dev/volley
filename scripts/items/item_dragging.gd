class_name ItemDragging
extends Control

@export var art_viewport: SubViewport
@export var art_viewport_container: SubViewportContainer

## Rendered art size in pixels; consumers use this for layout math.
var visible_size: Vector2


func show_item(definition: ItemDefinition) -> void:
	if definition == null or definition.art == null:
		return
	var art_instance: ItemArt = definition.art.instantiate()
	art_viewport.add_child(art_instance)
	var bounds: Rect2 = art_instance.bounding_rect
	assert(bounds.size != Vector2.ZERO, "ItemArt %s has no bounding_rect" % definition.key)
	art_instance.position -= bounds.position
	art_viewport.size = Vector2i(bounds.size.ceil())
	art_viewport_container.custom_minimum_size = bounds.size
	custom_minimum_size = bounds.size
	visible_size = bounds.size
