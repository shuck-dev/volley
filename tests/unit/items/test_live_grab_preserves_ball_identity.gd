# Single-entity ball model: a live grab keeps the same Ball across grab → release.
# Canon: designs/01-prototype/tech/02-ball-lifecycle.md.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController


func _make_rack(manager: Node) -> RackDisplay:
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


func _make_drop_target(position: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 10000

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


func test_grab_keeps_same_ball_instance_in_registry() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var before: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(before, "precondition: live ball exists")

	assert_true(_drag.grab_live_ball("ball_alpha", false))

	var during: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(during, before, "registry still tracks the same instance during the grab")
	assert_eq(during.play_state, Ball.PlayState.OUT_HELD)


func test_court_release_keeps_same_ball_instance() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var before: Ball = _reconciler.get_ball_for_key("ball_alpha")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame

	assert_true(_drag.attempt_release(Vector2(50, -25)))

	var after: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(after, before, "same Ball instance survives grab → court release")
	assert_ne(after.play_state, Ball.PlayState.OUT_HELD, "release transitions out of OUT_HELD")
	assert_false(after.freeze, "released ball unfreezes for physics")


func test_ball_removed_does_not_fire_on_live_grab() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var removed_count: int = 0
	_reconciler.ball_removed.connect(func(_ball: Ball) -> void: removed_count += 1)

	assert_true(_drag.grab_live_ball("ball_alpha", false))
	await get_tree().process_frame

	assert_eq(
		removed_count, 0, "live grab must not emit ball_removed; the Ball stays in the registry"
	)


func test_venue_drop_transitions_live_ball_to_out_rest() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var before: Ball = _reconciler.get_ball_for_key("ball_alpha")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame

	# Inside venue bounds, outside court bounds.
	assert_true(_drag.attempt_release(Vector2(1500, 50)))

	var after: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(after, before, "same Ball survives the floor drop")
	assert_eq(after.play_state, Ball.PlayState.OUT_REST)
	assert_false(after.freeze, "OUT_REST unfreezes so gravity integrates")
