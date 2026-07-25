class_name ItemTestHelpers
extends RefCounted

## Shared fixtures for ball-drag and reconciler test suites.

const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)
const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)

## Mirror of the priorities authored in the shipped scenes; lower is consulted first.
const CHARACTER_PRIORITY: int = 0
const RACK_PRIORITY: int = 20
const COURT_PRIORITY: int = 30
const VENUE_PRIORITY: int = 50


static func stub_art() -> PackedScene:
	var scene := PackedScene.new()
	var template := ItemArt.new()
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
	area.add_child(attach_rect_shape(size))
	test.add_child_autofree(area)
	return area


## Builds the rack, court and venue targets at production priorities so drop-target
## precedence in a test matches what the shipped scenes resolve to.
static func make_drop_targets(
	manager: Node, reconciler: Node, rack_position: Vector2, venue_bounds: Rect2, test: Node
) -> void:
	var rack_target: RackDropTarget = RackDropTargetScript.new()
	rack_target.item_manager = manager
	rack_target.role = &"ball"
	rack_target.priority = RACK_PRIORITY
	rack_target.position = rack_position
	rack_target.add_child(attach_rect_shape(Vector2(300, 200)))
	test.add_child_autofree(rack_target)

	var court_target: CourtDropTarget = CourtDropTargetScript.new()
	court_target.item_manager = manager
	court_target.reconciler = reconciler
	court_target.priority = COURT_PRIORITY
	test.add_child_autofree(court_target)

	var venue_target: VenueDropTarget = VenueDropTargetScript.new()
	venue_target.item_manager = manager
	venue_target.reconciler = reconciler
	venue_target.venue_bounds = venue_bounds
	venue_target.priority = VENUE_PRIORITY
	test.add_child_autofree(venue_target)


static func attach_rect_shape(size: Vector2) -> CollisionShape2D:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	return collision
