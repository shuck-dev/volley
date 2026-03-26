extends GutTest

var _paddle: CharacterBody2D


func before_each() -> void:
	_paddle = load("res://scripts/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
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
	await get_tree().create_timer(0.25).timeout
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.10, 0.001)


# --- reset_streak ---


func test_pitch_resets_to_baseline_on_first_hit_after_reset() -> void:
	_paddle.on_ball_hit()
	await get_tree().create_timer(0.25).timeout
	_paddle.on_ball_hit()
	_paddle.reset_streak()
	await get_tree().create_timer(0.25).timeout
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.05, 0.001)
