## BallReconciler.adopt_pre_existing_balls restores saved position and play_state
## per the slice in SaveManager.items, so reload lands the ball where the player left it.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler
var _ball: Ball


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	_manager.items.assign([ball_alpha] as Array[ItemDefinition])
	_manager.economy.soul_balance = 10000
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_ball = load("res://scenes/ball.tscn").instantiate()
	_ball.item_key = "ball_alpha"
	_ball.global_position = Vector2(100, 100)
	add_child_autofree(_ball)
	# Reconciler walks its parent's children for adoption.
	_reconciler.add_sibling.call_deferred(_ball)


func _seed_save(position: Vector2, play_state: int) -> void:
	SaveManager.items.ball_positions = {"ball_alpha": position} as Dictionary[String, Vector2]
	SaveManager.items.ball_play_states = {"ball_alpha": play_state} as Dictionary[String, int]


func test_adopt_restores_saved_out_rest_position_and_state() -> void:
	_seed_save(Vector2(500, 300), Ball.PlayState.OUT_REST)

	_reconciler.adopt_pre_existing_balls()

	assert_eq(_ball.play_state, Ball.PlayState.OUT_REST)
	assert_eq(_ball.global_position, Vector2(500, 300))
	assert_eq(_ball.linear_velocity, Vector2.ZERO)


func test_adopt_demotes_out_held_to_out_rest_on_load() -> void:
	_seed_save(Vector2(420, 250), Ball.PlayState.OUT_HELD)

	_reconciler.adopt_pre_existing_balls()

	# Drag context is gone on load; HELD demotes to REST so the ball is not stuck mid-air.
	assert_eq(_ball.play_state, Ball.PlayState.OUT_REST)
	assert_eq(_ball.global_position, Vector2(420, 250))


func test_adopt_restores_play_state_for_play_normal() -> void:
	_seed_save(Vector2(640, 400), Ball.PlayState.PLAY_NORMAL)

	_reconciler.adopt_pre_existing_balls()

	# enter_play picks NORMAL or ARC by Y vs soul_bound_y; both count as restored.
	assert_true(
		(
			_ball.play_state == Ball.PlayState.PLAY_NORMAL
			or _ball.play_state == Ball.PlayState.PLAY_ARC
		)
	)
