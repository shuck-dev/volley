## Verifies the reconciler keeps the same Ball instance across grab, release, re-grab, and re-release.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)
const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)

const VENUE_BOUNDS: Rect2 = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: ItemDragController


func before_each() -> void:
	_manager = ItemManagerScript.new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([ItemTestHelpersScript.make_ball_item("ball_alpha")])
	_manager.economy.soul_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	_host.name = "BallHost"
	add_child_autofree(_host)

	_rack = _build_rack(_manager)
	_drop_target = _build_drop_target(Vector2(-1500, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_host.add_child(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	add_child_autofree(_drag)

	var rack_target: RackDropTarget = RackDropTargetScript.new()
	rack_target.configure(_manager, _drop_target, &"ball")
	autofree(rack_target)
	_drag.register_target(rack_target)

	var court_target: CourtDropTarget = CourtDropTargetScript.new()
	court_target.configure(_manager, _reconciler, _host.get_world_2d(), Rect2())
	autofree(court_target)
	_drag.register_target(court_target)

	var venue_target: VenueDropTarget = VenueDropTargetScript.new()
	venue_target.configure(_manager, _reconciler, VENUE_BOUNDS)
	autofree(venue_target)
	_drag.register_target(venue_target)


func after_each() -> void:
	await get_tree().process_frame


func _build_rack(manager: Node) -> RackDisplay:
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
	add_child_autofree(rack)
	return rack


func _build_drop_target(center: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = center
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func _seed_release_velocity(start: Vector2, end: Vector2) -> void:
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": start})
	_drag._cursor_samples.append({"time": 0.04, "position": end})


func test_regrab_preserves_instance_id() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live, "precondition: an in-play Ball exists")
	var live_id: int = live.get_instance_id()

	assert_true(_drag.grab_live_ball("ball_alpha", false))
	_drag._gesture_below_threshold = false
	_seed_release_velocity(Vector2.ZERO, Vector2(10, 0))
	assert_true(_drag.attempt_release(Vector2(50, 25)))

	var first_release: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(first_release.get_instance_id(), live_id)

	assert_true(_drag.grab_live_ball("ball_alpha", false))
	assert_eq(_reconciler.get_ball_for_key("ball_alpha").play_state, Ball.PlayState.OUT_HELD)

	_drag._gesture_below_threshold = false
	_seed_release_velocity(Vector2(10, 0), Vector2(20, 0))
	assert_true(_drag.attempt_release(Vector2(50, 25)))

	assert_eq(_reconciler.get_ball_for_key("ball_alpha").get_instance_id(), live_id)
