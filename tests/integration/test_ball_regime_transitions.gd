## End-to-end ball regime transitions; see designs/01-prototype/design/21-ball-dynamics.md#regime-unification.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const BallScene: PackedScene = preload("res://scenes/ball.tscn")
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
var _drag: ItemDragController


func before_each() -> void:
	_manager = ItemManagerScript.new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	_manager.items.assign(typed_items)
	_manager.economy.soul_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	_host.name = "BallHost"
	add_child_autofree(_host)

	_rack = _build_rack(_manager)

	_drop_target = _build_drop_target(RACK_CENTER, RACK_SIZE)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	# The host injects the container whose authored Balls are adopted, as Court does in court.tscn.
	_reconciler.pre_existing_balls_parent = _host
	_host.add_child(_reconciler)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = COURT_BOUNDS
	_drag.venue_bounds = VENUE_BOUNDS
	add_child_autofree(_drag)


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


func _permanent_balls() -> Array:
	# Includes both reconciler-spawned and authored-adopted balls (the latter keep their original parent).
	var result: Array = []
	for child in _reconciler.get_children():
		if child is Ball and not (child as Ball).is_temporary:
			result.append(child)
	for child in _host.get_children():
		if child is Ball and not (child as Ball).is_temporary:
			result.append(child)
	return result


func _all_balls_under_host() -> Array:
	var result: Array = []
	for child in _reconciler.get_children():
		if child is Ball:
			result.append(child)
	for child in _host.get_children():
		if child is Ball:
			result.append(child)
	return result


# --- Scenario 1: rack -> court via drag spawns a Ball in play ---------------


func test_drag_permanent_ball_off_court_onto_rack_regrows_token() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var placed_min: float = Stats.resolve(
		GameRules.base.ball_speed_min, &"ball_speed_min", _manager
	)
	assert_true(_manager.is_on_court("training_ball"), "precondition: ball placed")
	assert_not_null(_reconciler.get_ball_for_key("training_ball"), "precondition: live ball exists")

	_drag.grab_live_ball("training_ball")
	await get_tree().process_frame
	var released: bool = _drag.attempt_release(_drop_target.global_position)

	assert_true(released)
	await get_tree().process_frame
	assert_false(
		_manager.is_on_court("training_ball"),
		"rack release should deactivate a permanent ball",
	)
	# Registry membership = existence; the Ball survives, transitioned to STORED at its rack slot.
	var stored: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(stored, "reconciler keeps tracking; deactivate transitions to STORED")
	assert_eq(
		stored.play_state, Ball.PlayState.STORED, "rack release transitions the Ball to STORED"
	)
	assert_eq(_permanent_balls().size(), 1, "one Ball instance persists through court -> rack")
	assert_lt(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager),
		placed_min,
		"effect should deregister once the ball is stored again",
	)
	assert_true(
		"training_ball" in _rack.get_displayed_keys(),
		"rack refresh should regrow the token in its slot",
	)


# --- Scenario 3: rack -> mid-venue release drops loose (SH-314) -------------


func test_drag_ball_onto_mid_venue_position_drops_loose() -> void:
	_manager.take("training_ball")
	_drag.grab_from_rack("training_ball")
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame

	var in_venue_outside_court := Vector2(1500, 50)
	var released: bool = _drag.attempt_release(in_venue_outside_court)

	assert_true(released, "release inside venue always resolves")
	# Step 5: the at-rest ball lives as a Ball in OUT_REST in the registry, not a HeldBody.
	assert_false(
		_manager.is_on_court("training_ball"), "rack-origin venue release does not flip on-court"
	)
	assert_true(
		_manager.is_loose_in_venue("training_ball"), "rack filter relies on loose-in-venue overlay"
	)
	var ball: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(ball, "venue release registers the Ball with the reconciler")
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST)
	assert_false(ball.freeze, "OUT_REST unfreezes so gravity integrates")
	assert_gt(ball.gravity_scale, 0.0, "OUT_REST has gravity engaged")


# --- Scenario 6: save round-trip preserves live ball placement -------------


func test_save_round_trip_preserves_live_ball_placement() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var placed_min: float = Stats.resolve(
		GameRules.base.ball_speed_min, &"ball_speed_min", _manager
	)
	assert_not_null(_reconciler.get_ball_for_key("training_ball"), "precondition: live ball exists")

	var saved_blob: String = JSON.stringify(_manager.state.to_save_dict())

	var reloaded_manager: Node = ItemManagerScript.new()
	reloaded_manager.state = ItemState.new()
	reloaded_manager.state.apply_save_dict(JSON.parse_string(saved_blob))
	reloaded_manager.economy = EconomyState.new()
	reloaded_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	reloaded_manager.items.assign(typed_items)
	add_child_autofree(reloaded_manager)

	var reloaded_host := Node2D.new()
	reloaded_host.name = "ReloadedBallHost"
	add_child_autofree(reloaded_host)

	var reloaded_reconciler: BallReconciler = BallReconcilerScript.new()
	reloaded_reconciler.configure(reloaded_manager)
	reloaded_host.add_child(reloaded_reconciler)
	await get_tree().process_frame

	assert_true(
		reloaded_manager.is_on_court("training_ball"),
		"placement must survive the save/reload cycle",
	)
	var reloaded_ball: Ball = reloaded_reconciler.get_ball_for_key("training_ball")
	assert_not_null(reloaded_ball, "reconciler re-spawned the ball from progression on load")
	assert_true(
		reloaded_ball.get_parent() == reloaded_reconciler,
		"the live ball is parented under the reconciler",
	)
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", reloaded_manager),
		placed_min,
		0.01,
		"reloaded ball item must run the same effect as before the save",
	)

# --- Scenario 7 (SH-245): press-drag-release on rack drives full input pipeline -
