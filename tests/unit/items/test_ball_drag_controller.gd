## SH-218 drag controller owns the held token and reconciles rack <-> court transitions.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController


func _stub_art() -> PackedScene:
	var scene := PackedScene.new()
	scene.pack(Node2D.new())
	return scene


func _make_ball_item(key: String) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = key
	item.role = &"ball"
	item.base_cost = 10
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = []
	item.art = _stub_art()
	return item


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
	var ball_alpha := _make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	add_child_autofree(_drag)


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _host.get_children():
		if child is Ball:
			result.append(child)
	return result


func test_grab_from_rack_spawns_held_token_and_activates_item() -> void:
	_manager.take("ball_alpha")
	assert_false(_manager.is_on_court("ball_alpha"), "precondition: item is on the rack")

	var ok: bool = _drag.grab_from_rack("ball_alpha")
	assert_true(ok)
	assert_true(_drag.is_dragging(), "drag controller should be mid-gesture after rack pickup")
	assert_eq(_drag.get_held_key(), "ball_alpha")
	assert_true(
		_manager.is_on_court("ball_alpha"),
		"picking up a rack token should activate the item so the rack marks the slot spent",
	)


func test_rack_pickup_fails_when_item_unowned() -> void:
	assert_false(_drag.grab_from_rack("ball_alpha"), "cannot pick up an unowned item")
	assert_false(_drag.is_dragging())


func test_release_over_court_instates_a_ball_at_cursor_with_gesture_velocity() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	# Existing live ball from activation - remove it so we can assert the release-path spawn.
	for ball in _permanent_balls():
		ball.queue_free()
	await get_tree().process_frame

	var court_point := Vector2(100, 50)
	var released: bool = _drag.attempt_release(court_point)
	assert_true(released, "release over court should resolve")
	assert_false(_drag.is_dragging())

	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "reconciler should own the live ball after a court release")
	assert_eq(ball.global_position, court_point)


func test_release_outside_valid_zones_is_a_no_op_and_hold_continues() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var off_world := Vector2(99999, 99999)

	var released: bool = _drag.attempt_release(off_world)

	assert_false(released, "release outside valid zones should not resolve")
	assert_true(_drag.is_dragging(), "hold continues when release lands in no-mans-land")
	assert_eq(_drag.get_held_key(), "ball_alpha")


func test_release_over_rack_destroys_held_token_and_deactivates_permanent() -> void:
	_manager.take("ball_alpha")
	_drag.grab_from_rack("ball_alpha")
	var over_rack := _drop_target.global_position

	var released: bool = _drag.attempt_release(over_rack)

	assert_true(released)
	assert_false(_drag.is_dragging(), "held token destroyed on rack release")
	assert_false(
		_manager.is_on_court("ball_alpha"),
		"release onto rack should deactivate a permanent ball item",
	)


func test_mid_rally_grab_suspends_live_ball_and_takes_over_cursor() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(live, "precondition: live ball exists")

	var ok: bool = _drag.grab_live_ball("ball_alpha", false)
	assert_true(ok)
	assert_true(_drag.is_dragging())
	await get_tree().process_frame
	assert_false(is_instance_valid(live), "live ball should be freed on mid-rally grab")
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"reconciler should release its tracked live ball during the hold",
	)


func test_mid_rally_grab_then_release_over_court_reinstates_a_ball() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame

	var court_point := Vector2(50, -25)
	var released: bool = _drag.attempt_release(court_point)

	assert_true(released)
	var reinstated: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(reinstated, "court release should reinstate a Ball via the reconciler")
	assert_eq(reinstated.global_position, court_point)


func test_temporary_ball_release_over_court_does_not_spawn_through_reconciler() -> void:
	_drag.grab_live_ball("ball_alpha", true)
	var court_point := Vector2(0, 0)

	var released: bool = _drag.attempt_release(court_point)

	assert_true(released)
	assert_null(
		_reconciler.get_ball_for_key("ball_alpha"),
		"temporary balls are outside the reconciler's placement-driven set",
	)


func test_rack_slot_press_triggers_drag_pickup() -> void:
	_manager.take("ball_alpha")

	_rack.press_slot("ball_alpha")

	assert_true(_drag.is_dragging(), "rack slot press should start the drag gesture")
	assert_eq(_drag.get_held_key(), "ball_alpha")
