class_name ItemTestHelpers
extends RefCounted

## Shared fixtures for ball-drag and reconciler test suites.


static func stub_art() -> PackedScene:
	var scene := PackedScene.new()
	scene.pack(Node2D.new())
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
	return item
