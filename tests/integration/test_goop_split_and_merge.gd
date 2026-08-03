## Verifies Goop's split-on-tier-advance and merge-on-contact behaviour through the reconciler.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const GoopBallScene: PackedScene = preload("res://scenes/balls/goop_ball.tscn")

var _manager: Node
var _reconciler: BallReconciler
var _goop: GoopBall


func before_each() -> void:
	_manager = BallFactory.create_manager(self)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

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
