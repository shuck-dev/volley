extends GutTest

const CheaterBallScript: GDScript = preload("res://scripts/entities/ball/cheater_ball.gd")


func _spawn_cheater_ball() -> CheaterBall:
	var ball: CheaterBall = CheaterBallScript.new()
	add_child_autofree(ball)
	return ball


func test_wobble_preserves_speed() -> void:
	var ball: CheaterBall = _spawn_cheater_ball()
	ball.linear_velocity = Vector2(ball.scaled_speed, 0.0)

	# A delta past max_interval_seconds guarantees the wobble fires within this single tick.
	ball._physics_process(ball.max_interval_seconds + 0.1)

	assert_almost_eq(ball.linear_velocity.length(), ball.scaled_speed, 0.01)


func test_wobble_rotates_velocity_direction() -> void:
	var ball: CheaterBall = _spawn_cheater_ball()
	var original_direction: Vector2 = Vector2(ball.scaled_speed, 0.0)
	ball.linear_velocity = original_direction

	ball._physics_process(ball.max_interval_seconds + 0.1)

	assert_ne(
		ball.linear_velocity.angle(),
		original_direction.angle(),
		"wobble should rotate the velocity, not leave it unchanged",
	)
