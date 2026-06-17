extends GutTest

const PaddleScript := preload("res://scripts/entities/paddle.gd")


func test_racket_rejects_ball_moving_away_from_paddle() -> void:
	var paddle := _new_paddle_at(-300)
	watch_signals(paddle)
	var ball := Ball.new()
	add_child_autofree(ball)
	ball.linear_velocity = Vector2(100, 0)
	paddle._on_racket_body_entered(ball)
	assert_signal_not_emitted(paddle, "paddle_hit")


func _new_paddle_at(x: float) -> Paddle:
	var paddle := PaddleScript.new()
	paddle.position = Vector2(x, 0)
	var sound := AudioStreamPlayer.new()
	paddle.add_child(sound)
	paddle.hit_sound = sound
	var tracker := HitTracker.new()
	paddle.tracker = tracker
	paddle.add_child(tracker)
	add_child_autofree(paddle)
	return paddle
