extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ComebackBallScript: GDScript = preload("res://scripts/entities/ball/comeback_ball.gd")

var _reconciler: BallReconciler
var _paddle: Node2D


func before_each() -> void:
	_paddle = Node2D.new()
	add_child_autofree(_paddle)

	_reconciler = BallReconcilerScript.new()
	_reconciler.player_paddle = _paddle
	add_child_autofree(_reconciler)


func _spawn_comeback_ball() -> ComebackBall:
	var ball: ComebackBall = ComebackBallScript.new()
	_reconciler.add_child(ball)
	return ball


func test_attract_curves_toward_paddle_when_heading_toward_it() -> void:
	var ball: ComebackBall = _spawn_comeback_ball()
	ball.global_position = Vector2.ZERO
	_paddle.global_position = Vector2(100.0, 50.0)
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	ball._physics_process(1.0)

	assert_gt(ball.linear_velocity.y, 0.0, "heading toward the paddle should curve down toward it")


func test_attract_preserves_speed() -> void:
	var ball: ComebackBall = _spawn_comeback_ball()
	ball.global_position = Vector2.ZERO
	_paddle.global_position = Vector2(100.0, 50.0)
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	ball._physics_process(1.0)

	assert_almost_eq(ball.linear_velocity.length(), ball.scaled_speed, 0.01)


func test_attract_does_nothing_when_moving_away_from_paddle() -> void:
	var ball: ComebackBall = _spawn_comeback_ball()
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
	var ball: ComebackBall = _spawn_comeback_ball()
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
	var ball: ComebackBall = _spawn_comeback_ball()
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	assert_true(ball.rescue(), "a fresh charge should let the rescue start")


func test_rescue_does_not_activate_when_uncharged() -> void:
	var ball: ComebackBall = _spawn_comeback_ball()
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)
	ball.rescue()

	assert_false(ball.rescue(), "a second rescue attempt should fail with no charge left")
