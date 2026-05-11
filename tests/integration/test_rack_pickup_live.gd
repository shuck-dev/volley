# Rack pickups grab the STORED Ball directly; no HeldBody spawn for ball-role.
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
	_manager._progression.friendship_point_balance = 10000

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


func _seed_stored_ball() -> Ball:
	_manager.take("ball_alpha")
	var ball: Ball = _reconciler.adopt_stored("ball_alpha", Vector2(50, 0))
	assert_not_null(ball, "precondition: adopt_stored returns a Ball")
	return ball


func test_rack_grab_adopts_stored_ball_no_held_body() -> void:
	var stored: Ball = _seed_stored_ball()

	var removed_count: int = 0
	_reconciler.ball_removed.connect(func(_b: Ball) -> void: removed_count += 1)

	assert_true(_drag.grab_from_rack("ball_alpha", Vector2(50, 0)))

	assert_eq(_drag._held_ball, stored, "rack grab adopts the STORED Ball as held")
	assert_null(_drag._held_body, "no HeldBody spawn on ball-role rack grab")
	assert_eq(stored.play_state, Ball.PlayState.OUT_HELD)
	assert_eq(removed_count, 0, "rack pickup does not emit ball_removed")
	assert_eq(_reconciler.get_ball_for_key("ball_alpha"), stored, "ball stays in registry")


func test_rack_grab_release_over_court_transitions_to_play() -> void:
	var stored: Ball = _seed_stored_ball()
	assert_true(_drag.grab_from_rack("ball_alpha", Vector2(50, 0)))
	await get_tree().process_frame

	assert_true(_drag.attempt_release(Vector2(50, -25)))

	var after: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(after, stored, "same Ball instance survives rack pickup → court release")
	assert_ne(after.play_state, Ball.PlayState.OUT_HELD, "release transitions out of OUT_HELD")
	assert_false(after.freeze, "play state unfreezes the body")


func test_rack_grab_cancel_restores_stored_state() -> void:
	var stored: Ball = _seed_stored_ball()
	assert_true(_drag.grab_from_rack("ball_alpha", Vector2(50, 0)))
	assert_eq(stored.play_state, Ball.PlayState.OUT_HELD)

	# Press-and-release without movement: cancels back to source.
	assert_true(_drag.attempt_release(Vector2(50, 0)))

	var after: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(after, stored, "cancelled rack pickup keeps the same Ball in the registry")
	assert_eq(after.play_state, Ball.PlayState.STORED, "cancelled pickup returns to STORED")
	assert_true(after.freeze, "STORED freezes the body")
