extends GutTest

const PaddleScript := preload("res://scripts/entities/paddle.gd")

var _paddle: Paddle


func before_each() -> void:
	_paddle = PaddleScript.new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	add_child_autofree(_paddle)


# --- on_ball_hit ---
func test_on_ball_hit_emits_paddle_hit_signal() -> void:
	watch_signals(_paddle)
	_paddle.on_ball_hit()
	assert_signal_emitted(_paddle, "paddle_hit")


func test_pitch_increases_on_first_hit() -> void:
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.05, 0.001)


func test_second_hit_during_cooldown_does_not_change_pitch() -> void:
	_paddle.on_ball_hit()
	var pitch_after_first: float = _paddle.hit_sound.pitch_scale
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, pitch_after_first, 0.001)


func test_pitch_increases_after_cooldown_expires() -> void:
	_paddle.on_ball_hit()
	_paddle.tracker._process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.10, 0.001)


# --- _on_racket_body_entered directional gate ---
func test_racket_rejects_ball_moving_away_from_paddle() -> void:
	_paddle.position = Vector2(-300, 0)
	_paddle._lane_x = -300.0

	watch_signals(_paddle)
	var ball := Ball.new()
	add_child_autofree(ball)
	ball.linear_velocity = Vector2(-100, 0)
	_paddle._on_racket_body_entered(ball)
	assert_signal_not_emitted(_paddle, "paddle_hit")


# --- reset_streak ---
func test_pitch_resets_to_baseline_on_first_hit_after_reset() -> void:
	_paddle.on_ball_hit()
	_paddle.tracker._process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	_paddle.reset_streak()
	_paddle.tracker._process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.05, 0.001)
