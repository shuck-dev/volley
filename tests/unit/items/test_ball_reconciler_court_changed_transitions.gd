## SH-374 step 7.3: court_changed transitions instead of destroying when stored_balls_in_registry is on.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler
var _rack: RackDisplay
var _ball_removed_count: int = 0


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


func _count_removed(_ball: Ball) -> void:
	_ball_removed_count += 1


func before_each() -> void:
	_ball_removed_count = 0
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var ball_beta: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_beta")
	var typed_items: Array[ItemDefinition] = [ball_alpha, ball_beta]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_rack = _make_rack(_manager)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_reconciler.ball_rack = _rack
	add_child_autofree(_reconciler)
	_reconciler.ball_removed.connect(_count_removed)


func _ball_count() -> int:
	var count := 0
	for child in _reconciler.get_children():
		if child is Ball:
			count += 1
	return count


func test_flag_on_on_court_true_transitions_stored_ball_to_play() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	await get_tree().process_frame

	var stored: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_eq(stored.play_state, Ball.PlayState.STORED, "precondition: ball starts STORED")
	var instance_id := stored.get_instance_id()

	_manager.activate("ball_alpha")
	await get_tree().process_frame

	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "registry entry survives state flip")
	assert_eq(ball.get_instance_id(), instance_id, "same Ball instance reused, not respawned")
	var is_play_state: bool = (
		ball.play_state == Ball.PlayState.PLAY_NORMAL or ball.play_state == Ball.PlayState.PLAY_ARC
	)
	assert_true(is_play_state, "ball transitioned to a PLAY state")
	assert_eq(_ball_count(), 1, "no extra Ball spawned during STORED->PLAY transition")


func test_flag_on_on_court_false_transitions_play_ball_to_stored() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	await get_tree().process_frame

	var ball_before: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball_before)
	var instance_id := ball_before.get_instance_id()
	var removed_before: int = _ball_removed_count

	_manager.deactivate("ball_alpha")
	await get_tree().process_frame

	var ball_after: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball_after, "registry entry survives deactivate")
	assert_eq(ball_after.get_instance_id(), instance_id, "same Ball instance reused")
	assert_eq(ball_after.play_state, Ball.PlayState.STORED, "deactivate transitions to STORED")
	assert_false(ball_after.is_queued_for_deletion(), "ball is not queue_freed on deactivate")
	assert_eq(_ball_removed_count, removed_before, "ball_removed does not fire on state transition")
	assert_eq(
		ball_after.global_position,
		_rack.get_slot_position_for("ball_alpha"),
		"ball repositioned to rack slot"
	)


func test_flag_on_round_trip_stored_play_stored_keeps_single_instance() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	await get_tree().process_frame
	var instance_id := _reconciler.get_ball_for_key("ball_alpha").get_instance_id()
	var removed_baseline: int = _ball_removed_count

	_manager.activate("ball_alpha")
	await get_tree().process_frame
	_manager.deactivate("ball_alpha")
	await get_tree().process_frame
	_manager.activate("ball_alpha")
	await get_tree().process_frame

	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball)
	assert_eq(ball.get_instance_id(), instance_id, "single stable Ball across the round trip")
	assert_eq(_ball_count(), 1, "no proliferation across STORED<->PLAY trips")
	assert_eq(
		_ball_removed_count, removed_baseline, "zero ball_removed emissions across round trip"
	)


func test_bring_into_play_reuses_out_rest_ball_via_enter_play() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	await get_tree().process_frame
	# Start at rest so reuse must transition; release_into_rest lands an OUT_REST Ball under the same key.
	var rested: Ball = _reconciler.release_into_rest("ball_alpha", Vector2(50, 50), Vector2.ZERO)
	assert_eq(rested.play_state, Ball.PlayState.OUT_REST, "precondition: ball is OUT_REST")
	var instance_id := rested.get_instance_id()

	var played: Ball = _reconciler.bring_into_play("ball_alpha", Vector2(120, 30), Vector2(80, 0))
	assert_eq(played.get_instance_id(), instance_id, "bring_into_play reuses the existing Ball")
	var is_play_state: bool = (
		played.play_state == Ball.PlayState.PLAY_NORMAL
		or played.play_state == Ball.PlayState.PLAY_ARC
	)
	assert_true(is_play_state, "reuse path runs enter_play, leaving a PLAY state")


func test_flag_off_destroy_on_deactivate_path_still_fires() -> void:
	# Flag stays false; existing destroy-on-deactivate behaviour must continue to hold.
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	assert_eq(_ball_count(), 1, "precondition: one live ball before deactivate")

	_manager.deactivate("ball_alpha")
	await get_tree().process_frame

	assert_eq(_ball_count(), 0, "flag-off path still destroys on deactivate")
	assert_null(_reconciler.get_ball_for_key("ball_alpha"))
	assert_eq(_ball_removed_count, 1, "ball_removed still fires on flag-off destroy")
