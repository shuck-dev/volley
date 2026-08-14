## Verifies Goop's split-on-tier-advance and merge-on-contact behaviour through the reconciler.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const GoopBallScene: PackedScene = preload("res://scenes/balls/goop_ball.tscn")

var _manager: Node
var _reconciler: Node
var _goop: GoopBall
var _drag: ItemDragController


func before_each() -> void:
	_manager = BallFactory.create_manager(self)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	var rack: RackDisplay = BallTestHelpers.make_rack(_manager, self)
	var drop_target: Area2D = BallTestHelpers.make_drop_area(
		Vector2(-1000, 0), Vector2(300, 200), self
	)
	BallTestHelpers.make_drop_targets(_manager, _reconciler, drop_target.position, self)

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, rack, drop_target, _reconciler)
	_drag.kit = BallTestHelpers.make_kit(_manager, self)
	add_child_autofree(_drag)

	_goop = GoopBallScene.instantiate()
	_reconciler.add_child(_goop)
	_goop.linear_velocity = Vector2(800.0, 0.0)


func after_each() -> void:
	await get_tree().process_frame


func _split() -> Ball:
	watch_signals(_reconciler)
	_goop.tier_advanced.emit(_goop, 2)
	await wait_for_signal(_reconciler.ball_spawned, 1.0)
	return get_signal_parameters(_reconciler, "ball_spawned")[1]


func test_tier_advance_spawns_temporary_goop_child() -> void:
	var child: Ball = await _split()

	assert_true(child is GoopBall, "split spawns a GoopBall")
	assert_true(child.is_temporary, "split child is temporary")
	assert_eq(child.get_parent(), _reconciler)


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


func test_goop_temporary_children_do_not_merge_with_each_other() -> void:
	var child_1: GoopBall = await _split()
	child_1._physics_process(GoopBall.MERGE_GRACE_SECONDS + 0.1)

	watch_signals(_reconciler)
	child_1.tier_advanced.emit(child_1, 3)
	await wait_for_signal(_reconciler.ball_spawned, 1.0)

	var child_2: GoopBall = get_signal_parameters(_reconciler, "ball_spawned")[1]
	child_2._physics_process(GoopBall.MERGE_GRACE_SECONDS + 0.1)

	child_1.body_entered.emit(child_2)
	child_2.body_entered.emit(child_1)
	await get_tree().process_frame

	assert_true(
		is_instance_valid(child_1), "temporary child survives contact with another temporary child"
	)
	assert_true(
		is_instance_valid(child_2), "temporary child survives contact with another temporary child"
	)


func test_releasing_split_child_off_court_frees() -> void:
	var child: Ball = await _split()
	_drag.grab_temporary(child)

	var venue_point := Vector2(-1000, 0)
	assert_true(_drag.attempt_release(venue_point))
	await get_tree().process_frame

	assert_false(is_instance_valid(child), "release off-court frees the temporary child")
