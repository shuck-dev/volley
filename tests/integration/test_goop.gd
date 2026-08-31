## Verifies Goop's split-on-tier-advance and merge-on-contact behaviour through the ball_tracker.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const GoopBallScene: PackedScene = preload("res://scenes/balls/goop_ball.tscn")

var _goop: GoopBall
var _drag: ItemDragController


func before_each() -> void:
	BallTestHelpers.use_autoloads(self, [BallTestHelpers.make_ball_item("ball_alpha")])

	BallTestHelpers.make_drop_targets(self)

	_drag = ItemDragControllerScript.new()
	add_child_autofree(_drag)

	_goop = GoopBallScene.instantiate()
	BallTracker.add_child(_goop)
	_goop.linear_velocity = Vector2(800.0, 0.0)


func after_each() -> void:
	await get_tree().process_frame


func _split() -> Ball:
	watch_signals(BallTracker)
	_goop.tier_advanced.emit(_goop, 2)
	await wait_for_signal(BallTracker.ball_added, 1.0)
	return get_signal_parameters(BallTracker, "ball_added")[0]


func test_tier_advance_spawns_temporary_goop_child() -> void:
	var child: Ball = await _split()

	assert_true(child is GoopBall, "split spawns a GoopBall")
	assert_true(child.is_temporary, "split child is temporary")
	assert_eq(child.get_parent(), BallTracker)


func test_goop_contact_after_grace_frees_temporary_child() -> void:
	var child: Ball = await _split()
	_goop._physics_process(GoopBall.MERGE_GRACE_SECONDS + 0.1)
	child._physics_process(GoopBall.MERGE_GRACE_SECONDS + 0.1)

	child.body_entered.emit(_goop)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_false(is_instance_valid(child), "temporary child freed on merge")
	assert_true(is_instance_valid(_goop), "original goop survives the merge")


func test_goop_contact_during_grace_keeps_child() -> void:
	var child: Ball = await _split()

	child.body_entered.emit(_goop)
	await get_tree().process_frame

	assert_true(is_instance_valid(child), "grace window blocks the merge")


func test_releasing_split_child_off_court_frees() -> void:
	var child: Ball = await _split()
	_drag.grab_temporary(child)

	var venue_point := Vector2(-1000, 0)
	assert_true(_drag.attempt_release(venue_point))
	await get_tree().process_frame

	assert_false(is_instance_valid(child), "release off-court frees the temporary child")
