class_name BallTestHelpers
extends RefCounted

## Shared fixtures for ball-drag and ball_tracker test suites.

const BallKitScript: GDScript = preload("res://scripts/items/ball_kit.gd")
const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)

## Drop regions wide enough that a test releasing near the origin lands inside them.
const COURT_SIZE: Vector2 = Vector2(1600, 720)
const VENUE_SIZE: Vector2 = Vector2(4000, 2400)

## Mirror of the priorities authored in the shipped scenes.
const COURT_PRIORITY: int = 30
const VENUE_PRIORITY: int = 50

## Mirrors ItemDragController's shared collision shape for tests exercising can_accept/make_for directly.
static var collision_shape: CircleShape2D


static func _static_init() -> void:
	collision_shape = CircleShape2D.new()
	collision_shape.radius = 7.2


## Real ball.tscn instance so every BallDefinition has an instantiable scene.
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


static func make_kit(manager: Node, test: Node, capacity: int = 3) -> BallKit:
	var kit: BallKit = BallKitScript.new()
	var slot_container := HBoxContainer.new()
	slot_container.name = "SlotContainer"
	kit.add_child(slot_container)
	kit.slot_container = slot_container
	kit.capacity = capacity
	kit.configure(manager)
	test.add_child_autofree(kit)
	return kit


## Priorities mirror the shipped scenes so precedence in a test resolves as it does in play.
static func make_drop_targets(manager: Node, ball_tracker: Node, test: Node) -> void:
	var court_target: CourtDropTarget = CourtDropTargetScript.new()
	court_target.ball_manager = manager
	court_target.ball_tracker = ball_tracker
	court_target.priority = COURT_PRIORITY
	court_target.add_child(attach_rect_shape(COURT_SIZE))
	test.add_child_autofree(court_target)

	var venue_target: VenueDropTarget = VenueDropTargetScript.new()
	venue_target.ball_manager = manager
	venue_target.ball_tracker = ball_tracker
	venue_target.priority = VENUE_PRIORITY
	venue_target.add_child(attach_rect_shape(VENUE_SIZE))
	test.add_child_autofree(venue_target)


static func attach_rect_shape(size: Vector2) -> CollisionShape2D:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	return collision
