class_name ItemTestHelpers
extends RefCounted

## Shared fixtures for ball-drag and reconciler test suites.

const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")


static func stub_art() -> PackedScene:
	var scene := PackedScene.new()
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
	var default_shape := CircleShape2D.new()
	default_shape.radius = 7.2
	item.at_rest_shape = default_shape
	return item


static func make_equipment_item(key: String) -> ItemDefinition:
	var item := make_ball_item(key)
	item.role = &"equipment"
	return item


static func make_rack(manager: Node, test: Node) -> RackDisplay:
	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = &"ball"
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)
	for index in 4:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	rack.slot_container = slot_container
	rack.configure(manager)
	test.add_child_autofree(rack)
	return rack


static func make_drop_area(position: Vector2, size: Vector2, test: Node) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	test.add_child_autofree(area)
	return area
