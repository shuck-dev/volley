## Step 5: BallReconciler.release_into_rest is the registry seam venue-floor releases use.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 10000

	_host = Node2D.new()
	add_child_autofree(_host)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)


func _permanent_ball_count() -> int:
	var count := 0
	for child in _reconciler.get_children():
		if child is Ball:
			count += 1
	return count


func test_release_into_rest_creates_a_registry_ball_in_out_rest() -> void:
	_manager.take("ball_alpha")
	var position := Vector2(800, 600)
	var velocity := Vector2(15, 0)

	var ball: Ball = _reconciler.release_into_rest("ball_alpha", position, velocity)

	assert_not_null(ball, "release_into_rest returns the registry Ball")
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST)
	assert_eq(ball.global_position, position)
	assert_eq(ball.linear_velocity, velocity)
	assert_eq(_reconciler.get_ball_for_key("ball_alpha"), ball, "registry tracks the at-rest ball")
	assert_eq(_permanent_ball_count(), 1, "single registry entry post-release")


func test_release_into_rest_reuses_existing_ball_for_key() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var live: Ball = _reconciler.get_ball_for_key("ball_alpha")
	var live_id: int = live.get_instance_id()

	var rested: Ball = _reconciler.release_into_rest("ball_alpha", Vector2(800, 600), Vector2.ZERO)

	assert_eq(rested.get_instance_id(), live_id, "release_into_rest preserves identity")
	assert_eq(rested.play_state, Ball.PlayState.OUT_REST)
	assert_eq(_permanent_ball_count(), 1, "no duplicate spawn on already-tracked key")
