## SH-374 step 7.2: stored-branch initial population for the ball reconciler.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler
var _rack: RackDisplay


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


func before_each() -> void:
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


func _ball_count() -> int:
	var count := 0
	for child in _reconciler.get_children():
		if child is Ball:
			count += 1
	return count


func test_flag_off_does_not_populate_stored_kit_items() -> void:
	# Owned but not on-court; with flag off, no STORED ball spawns.
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	await get_tree().process_frame
	assert_eq(_ball_count(), 0, "flag off keeps stored-population dormant")


func test_flag_on_populates_stored_balls_for_kit_ball_items() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	await get_tree().process_frame

	var alpha: Ball = _reconciler.get_ball_for_key("ball_alpha")
	var beta: Ball = _reconciler.get_ball_for_key("ball_beta")
	assert_not_null(alpha, "stored-population spawns ball_alpha")
	assert_not_null(beta, "stored-population spawns ball_beta")
	assert_eq(alpha.play_state, Ball.PlayState.STORED, "stored-populated ball is in STORED state")
	assert_eq(beta.play_state, Ball.PlayState.STORED)
	assert_eq(alpha.get_parent(), _reconciler, "stored-populated ball parented under reconciler")
	# Slot positions are the rack's slot-marker globals; ball_alpha is the first kit entry.
	assert_eq(
		alpha.global_position,
		_rack.get_slot_position_for("ball_alpha"),
		"stored ball positioned at its rack slot"
	)


func test_mixed_kit_and_court_population_uses_both_branches() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	# Drive ball_alpha onto the court; the existing court branch handles it, kit branch handles ball_beta.
	_manager.activate("ball_alpha")
	await get_tree().process_frame

	var alpha: Ball = _reconciler.get_ball_for_key("ball_alpha")
	var beta: Ball = _reconciler.get_ball_for_key("ball_beta")
	assert_not_null(alpha, "court-branch spawn covers ball_alpha")
	assert_not_null(beta, "kit-branch spawn covers ball_beta")
	assert_ne(
		alpha.play_state,
		Ball.PlayState.STORED,
		"court item stays in a play state, not STORED",
	)
	assert_eq(beta.play_state, Ball.PlayState.STORED, "non-court kit item lands as STORED")


func test_collect_item_positions_skips_stored_balls() -> void:
	_reconciler.stored_balls_in_registry = true
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	_manager.activate("ball_alpha")
	await get_tree().process_frame

	var positions: Dictionary[String, Vector2] = _reconciler.collect_item_positions()
	assert_true(positions.has("ball_alpha"), "on-court ball position included in snapshot")
	assert_false(
		positions.has("ball_beta"),
		"STORED ball positions are reconstructed from rack slot index, not from world coords"
	)
