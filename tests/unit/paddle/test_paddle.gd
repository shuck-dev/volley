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


# --- reset_streak ---
func test_pitch_resets_to_baseline_on_first_hit_after_reset() -> void:
	_paddle.on_ball_hit()
	_paddle.tracker._process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	_paddle.reset_streak()
	_paddle.tracker._process(HitTracker.COOLDOWN)
	_paddle.on_ball_hit()
	assert_almost_eq(_paddle.hit_sound.pitch_scale, 1.05, 0.001)


# --- _apply_size ---
func test_apply_size_does_nothing_when_collision_not_assigned() -> void:
	_paddle._item_manager.item_level_changed.emit("paddle_size")
	assert_null(_paddle.collision)


func test_apply_size_keeps_foot_anchored_when_collider_grows() -> void:
	# Foot = position.y + half-height; growing the collider mid-frame must not push the foot through the floor.
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40.0, 20.0)
	_paddle._collision_shape = rect
	_paddle.position.y = 200.0
	_paddle._size_initialised = true  # Skip the initial-sizing branch; we are testing the live-resize path.
	var foot_before: float = _paddle.position.y + rect.size.y * 0.5

	_paddle._apply_size()

	var foot_after: float = _paddle.position.y + _paddle._collision_shape.size.y * 0.5
	assert_almost_eq(foot_after, foot_before, 0.001, "foot stays anchored after collider grows")
