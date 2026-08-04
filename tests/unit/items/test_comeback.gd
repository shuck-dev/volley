extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const BallManagerScript: GDScript = preload("res://scripts/items/ball_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/ball_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler
var _paddle: Node2D


func before_each() -> void:
	_manager = BallManagerScript.new()
	_manager.state = BallState.new()
	_manager.economy = EconomyState.new()
	_manager.economy.soul_balance = 10000
	add_child_autofree(_manager)

	_paddle = Node2D.new()
	add_child_autofree(_paddle)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_reconciler.player_paddle = _paddle
	add_child_autofree(_reconciler)


func _spawn_ball(ball_key: String) -> ComebackBall:
	_manager.take(ball_key)
	_manager.activate(ball_key)
	return _reconciler.get_ball_for_key(ball_key)


func _make_comeback_ball_item(key: String) -> BallDefinition:
	var item: BallDefinition = ItemTestHelpersScript.make_ball_item(key)
	item.scene = load("res://scenes/balls/comeback_ball.tscn")
	return item


func _spawn_comeback_ball(key: String) -> ComebackBall:
	var comeback_item: BallDefinition = _make_comeback_ball_item(key)
	var typed_items: Array[BallDefinition] = [comeback_item]
	_manager.items.assign(typed_items)
	return _spawn_ball(key)


func test_attract_curves_toward_paddle_when_heading_toward_it() -> void:
	var ball: ComebackBall = _spawn_comeback_ball("ball_comeback")
	ball.global_position = Vector2.ZERO
	_paddle.global_position = Vector2(100.0, 50.0)
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	ball._physics_process(1.0)

	assert_gt(ball.linear_velocity.y, 0.0, "heading toward the paddle should curve down toward it")


func test_attract_preserves_speed() -> void:
	var ball: ComebackBall = _spawn_comeback_ball("ball_comeback")
	ball.global_position = Vector2.ZERO
	_paddle.global_position = Vector2(100.0, 50.0)
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	ball._physics_process(1.0)

	assert_almost_eq(ball.linear_velocity.length(), ball.scaled_speed, 0.01)


func test_attract_does_nothing_when_moving_away_from_paddle() -> void:
	var ball: ComebackBall = _spawn_comeback_ball("ball_comeback")
	ball.global_position = Vector2.ZERO
	_paddle.global_position = Vector2(-100.0, 50.0)

	var original_velocity := Vector2(ball.scaled_speed, 0.0)
	ball.linear_velocity = original_velocity

	ball._physics_process(1.0)

	assert_eq(
		ball.linear_velocity.angle(),
		original_velocity.angle(),
		"moving away from the paddle should not curve toward it",
	)


func test_attract_does_nothing_outside_range() -> void:
	var ball: ComebackBall = _spawn_comeback_ball("ball_comeback")
	ball.global_position = Vector2.ZERO
	_paddle.global_position = Vector2(ball.attract_range + 100.0, 50.0)

	var original_velocity := Vector2(ball.scaled_speed, 0.0)
	ball.linear_velocity = original_velocity

	ball._physics_process(1.0)

	assert_eq(
		ball.linear_velocity.angle(),
		original_velocity.angle(),
		"a paddle outside attract_range should not curve the ball",
	)


func test_rescue_activates_when_charged() -> void:
	var ball: ComebackBall = _spawn_comeback_ball("ball_comeback")
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	assert_true(ball.rescue(), "a fresh charge should let the rescue start")


func test_rescue_does_not_activate_when_uncharged() -> void:
	var ball: ComebackBall = _spawn_comeback_ball("ball_comeback")
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)
	ball.rescue()

	assert_false(ball.rescue(), "a second rescue attempt should fail with no charge left")
