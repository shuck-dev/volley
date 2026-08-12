class_name BallTestHelpers
extends RefCounted

## Shared fixtures for ball-drag and reconciler test suites.

const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const BallKitDisplayScript: GDScript = preload("res://scripts/items/ball_kit_display.gd")
const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)
const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)

## Drop regions wide enough that a test releasing near the origin lands inside them.
const COURT_SIZE: Vector2 = Vector2(1600, 720)
const VENUE_SIZE: Vector2 = Vector2(4000, 2400)

## Mirror of the priorities authored in the shipped scenes; lower is consulted first.
const CHARACTER_PRIORITY: int = 0
const RACK_PRIORITY: int = 20
const COURT_PRIORITY: int = 30
const VENUE_PRIORITY: int = 50

## Mirrors ItemDragController's shared collision shape for tests exercising can_accept/make_for directly.
static var collision_shape: CircleShape2D


static func _static_init() -> void:
	collision_shape = CircleShape2D.new()
	collision_shape.radius = 7.2


## Real ball.tscn instance; every BallDefinition needs an instantiable scene for BallReconciler.
static func stub_ball_scene() -> PackedScene:
	return load("res://scenes/balls/ball.tscn")


static func make_ball_item(key: String) -> BallDefinition:
	var item := BallDefinition.new()
	item.key = key
	item.base_cost = 10
	item.cost_scaling = 2.0
	item.max_level = 3
	item.scene = stub_ball_scene()
	return item


static func make_rack(manager: Node, test: Node) -> RackDisplay:
	var rack: RackDisplay = RackDisplayScript.new()
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


static func make_kit(manager: Node, test: Node, capacity: int = 3) -> BallKitDisplay:
	var kit: BallKitDisplay = BallKitDisplayScript.new()
	var slot_container := HBoxContainer.new()
	slot_container.name = "SlotContainer"
	kit.add_child(slot_container)
	kit.slot_container = slot_container
	kit.capacity = capacity
	kit.configure(manager)
	test.add_child_autofree(kit)
	return kit


static func make_drop_area(position: Vector2, size: Vector2, test: Node) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	area.add_child(attach_rect_shape(size))
	test.add_child_autofree(area)
	return area


## Priorities mirror the shipped scenes so precedence in a test resolves as it does in play.
static func make_drop_targets(
	manager: Node, reconciler: Node, rack_position: Vector2, test: Node
) -> void:
	var rack_target: RackDropTarget = RackDropTargetScript.new()
	rack_target.ball_manager = manager
	rack_target.priority = RACK_PRIORITY
	rack_target.position = rack_position
	rack_target.add_child(attach_rect_shape(Vector2(300, 200)))
	test.add_child_autofree(rack_target)

	var court_target: CourtDropTarget = CourtDropTargetScript.new()
	court_target.ball_manager = manager
	court_target.reconciler = reconciler
	court_target.priority = COURT_PRIORITY
	court_target.add_child(attach_rect_shape(COURT_SIZE))
	test.add_child_autofree(court_target)

	var venue_target: VenueDropTarget = VenueDropTargetScript.new()
	venue_target.ball_manager = manager
	venue_target.reconciler = reconciler
	venue_target.priority = VENUE_PRIORITY
	venue_target.add_child(attach_rect_shape(VENUE_SIZE))
	test.add_child_autofree(venue_target)


static func attach_rect_shape(size: Vector2) -> CollisionShape2D:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	return collision
