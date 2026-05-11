## Verifies BallReconciler.adopt_stored spawns and registers a STORED Ball.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler
var _added_count: int
var _spawned_count: int
var _last_spawned_key: String
var _last_spawned_ball: Ball


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [alpha]
	_manager.items.assign(typed_items)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_added_count = 0
	_spawned_count = 0
	_last_spawned_key = ""
	_last_spawned_ball = null
	_reconciler.ball_added.connect(_on_ball_added)
	_reconciler.ball_spawned.connect(_on_ball_spawned)


func _on_ball_added(_ball: Ball) -> void:
	_added_count += 1


func _on_ball_spawned(item_key: String, ball: Ball) -> void:
	_spawned_count += 1
	_last_spawned_key = item_key
	_last_spawned_ball = ball


func test_adopt_stored_spawns_and_registers() -> void:
	var ball: Ball = _reconciler.adopt_stored("ball_alpha", Vector2(10, 20))
	assert_not_null(ball, "adopt_stored returns the spawned ball when flag is on")
	assert_eq(ball.get_parent(), _reconciler, "spawned ball parented to the reconciler")
	assert_eq(ball.play_state, Ball.PlayState.STORED, "spawned ball enters STORED state")
	assert_eq(ball.global_position, Vector2(10, 20), "spawned ball lands at spawn_position")
	assert_eq(
		_reconciler.get_ball_for_key("ball_alpha"),
		ball,
		"reconciler tracks the ball under its item key",
	)
	assert_eq(_added_count, 1, "ball_added fires once")
	assert_eq(_spawned_count, 1, "ball_spawned fires once")
	assert_eq(_last_spawned_key, "ball_alpha", "ball_spawned carries the item key")
	assert_eq(_last_spawned_ball, ball, "ball_spawned carries the spawned instance")
