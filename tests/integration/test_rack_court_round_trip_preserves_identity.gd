## Sub-step 7.5: STORED -> PLAY -> STORED round trip keeps the same Ball; zero ball_removed across the loop.
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

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController
var _removed_count: int


func before_each() -> void:
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


func test_stored_to_play_to_stored_keeps_single_instance() -> void:
	_manager.take(TrainingBall.key)
	# Wait for the kit-walk to populate the STORED ball.
	await get_tree().process_frame
	await get_tree().process_frame

	var initial: Ball = _reconciler.get_ball_for_key(TrainingBall.key)
	assert_not_null(initial, "kit-walk populates a STORED ball for the owned kit item")
	assert_eq(initial.play_state, Ball.PlayState.STORED)
	var initial_id: int = initial.get_instance_id()
	var removed_baseline: int = _removed_count

	# STORED -> PLAY via activate (mirrors a court drop accept).
	_manager.activate(TrainingBall.key)
	await get_tree().process_frame
	var played: Ball = _reconciler.get_ball_for_key(TrainingBall.key)
	assert_not_null(played, "registry survives activation")
	assert_eq(played.get_instance_id(), initial_id, "same Ball reused into PLAY")
	var is_play_state: bool = (
		played.play_state == Ball.PlayState.PLAY_NORMAL
		or played.play_state == Ball.PlayState.PLAY_ARC
	)
	assert_true(is_play_state, "ball transitioned to a PLAY state")

	# PLAY -> STORED via deactivate (mirrors a rack drop accept).
	_manager.deactivate(TrainingBall.key)
	await get_tree().process_frame
	var stored_again: Ball = _reconciler.get_ball_for_key(TrainingBall.key)
	assert_not_null(stored_again, "registry survives deactivation")
	assert_eq(stored_again.get_instance_id(), initial_id, "same Ball reused back to STORED")
	assert_eq(stored_again.play_state, Ball.PlayState.STORED)

	assert_eq(
		_removed_count,
		removed_baseline,
		"zero ball_removed emissions across STORED -> PLAY -> STORED"
	)
