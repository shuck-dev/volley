extends GutTest

const PaddleScript := preload("res://scripts/entities/paddle.gd")

var _paddle: Paddle
var _sprite: AnimatedSprite2D


func before_each() -> void:
	_paddle = PaddleScript.new()

	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound

	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)

	var frames: SpriteFrames = load("res://resources/animations/sam.tres")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_paddle.add_child(_sprite)
	_paddle.sprite = _sprite

	add_child_autofree(_paddle)


# --- movement state transitions ---


func test_starts_idle() -> void:
	assert_eq(_paddle.get_movement_state(), Paddle.MovementState.IDLE)


func test_drive_with_nonzero_velocity_transitions_to_walk() -> void:
	_paddle.drive(100.0)
	assert_eq(_paddle.get_movement_state(), Paddle.MovementState.WALK)


func test_drive_with_zero_velocity_stays_idle() -> void:
	_paddle.drive(0.0)
	assert_eq(_paddle.get_movement_state(), Paddle.MovementState.IDLE)


func test_drive_zero_after_walk_transitions_back_to_idle() -> void:
	_paddle.drive(100.0)
	_paddle.drive(0.0)
	assert_eq(_paddle.get_movement_state(), Paddle.MovementState.IDLE)


# --- animation follows movement state ---


func test_idle_state_plays_idle_animation() -> void:
	_paddle.drive(0.0)
	assert_eq(_sprite.animation, &"idle")


func test_walk_state_plays_walk_animation() -> void:
	_paddle.drive(100.0)
	assert_eq(_sprite.animation, &"walk")


func test_returning_to_idle_resumes_idle_animation() -> void:
	_paddle.drive(100.0)
	_paddle.drive(0.0)
	assert_eq(_sprite.animation, &"idle")


# --- swing overlay ---


func test_swing_fires_swing_animation() -> void:
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing")


func test_swing_does_not_change_movement_state_when_idle() -> void:
	_paddle.on_ball_hit()
	assert_eq(_paddle.get_movement_state(), Paddle.MovementState.IDLE)


func test_swing_does_not_change_movement_state_when_walking() -> void:
	_paddle.drive(100.0)
	_paddle.on_ball_hit()
	assert_eq(_paddle.get_movement_state(), Paddle.MovementState.WALK)


func test_swing_resumes_idle_after_animation_finishes() -> void:
	_paddle.on_ball_hit()
	_sprite.animation_finished.emit()
	assert_eq(_sprite.animation, &"idle")


func test_swing_resumes_walk_after_animation_finishes_while_walking() -> void:
	_paddle.drive(100.0)
	_paddle.on_ball_hit()
	_sprite.animation_finished.emit()
	assert_eq(_sprite.animation, &"walk")
