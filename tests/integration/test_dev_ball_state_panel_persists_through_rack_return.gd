## Sub-step 7.5: court grab + rack drop preserves the Ball in the registry.
## DevBallStatePanel sources its rows from BallTracker.ball_added/ball_removed; if ball_removed
## fires on the rack-return path the row vanishes mid-gesture. Asserts the row count is stable.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")

const COURT_BOUNDS: Rect2 = Rect2(Vector2(-600, -400), Vector2(1200, 800))
const VENUE_BOUNDS: Rect2 = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
const RACK_CENTER: Vector2 = Vector2(-1500, 0)
const RACK_SIZE: Vector2 = Vector2(300, 200)
const COURT_RELEASE: Vector2 = Vector2(50, 25)

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController
var _added_count: int
var _removed_count: int


func before_each() -> void:
	_added_count = 0
	_removed_count = 0

	_manager = ItemManagerScript.new()
	_manager._progression = ProgressionData.new()
	_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	_host.name = "BallHost"
	add_child_autofree(_host)

	_rack = _build_rack(_manager)
	_drop_target = _build_drop_target(RACK_CENTER, RACK_SIZE)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_reconciler.ball_rack = _rack
	_host.add_child(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = COURT_BOUNDS
	_drag.venue_bounds = VENUE_BOUNDS
	add_child_autofree(_drag)

	_reconciler.ball_added.connect(func(_b: Ball) -> void: _added_count += 1)
	_reconciler.ball_removed.connect(func(_b: Ball) -> void: _removed_count += 1)


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


func test_grab_court_ball_drop_on_rack_keeps_panel_row() -> void:
	_manager.take(TrainingBall.key)
	_manager.activate(TrainingBall.key)
	await get_tree().process_frame

	var live: Ball = _reconciler.get_ball_for_key(TrainingBall.key)
	assert_not_null(live, "precondition: live ball is on court")
	var added_after_setup: int = _added_count
	var removed_after_setup: int = _removed_count

	# Grab the live court ball — same Ball instance becomes the drag target.
	assert_true(_drag.grab_live_ball(TrainingBall.key), "live grab succeeds")
	await get_tree().process_frame
	assert_eq(live.play_state, Ball.PlayState.OUT_HELD, "grabbed Ball is OUT_HELD")

	# Release over the rack drop target.
	assert_true(_drag.attempt_release(RACK_CENTER), "rack drop accepts the release")

	var after: Ball = _reconciler.get_ball_for_key(TrainingBall.key)
	assert_not_null(after, "DevBallStatePanel row source persists — Ball still in registry")
	assert_eq(after.get_instance_id(), live.get_instance_id(), "same Ball instance throughout")
	assert_eq(after.play_state, Ball.PlayState.STORED, "Ball transitioned to STORED at rack")
	assert_eq(_added_count, added_after_setup, "no spurious ball_added during grab+drop")
	assert_eq(
		_removed_count, removed_after_setup, "no ball_removed fired — DevBallStatePanel row stays"
	)
