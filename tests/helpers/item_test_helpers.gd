class_name ItemTestHelpers
extends RefCounted

## Shared fixtures for ball-drag and reconciler test suites.


static func stub_art() -> PackedScene:
	var scene := PackedScene.new()
	# PackedScene.pack snapshots the node but does not take ownership; freeing avoids a CanvasItem RID leak at exit.
	var template := Node2D.new()
	scene.pack(template)
	template.free()
	return scene


static func make_ball_item(key: String) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = key
	item.role = &"ball"
	item.base_cost = 10
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = []
	item.art = stub_art()
	# Production ball items always ship an at_rest_shape; fixtures match that contract.
	var default_shape := CircleShape2D.new()
	default_shape.radius = 7.2
	item.at_rest_shape = default_shape
	return item
