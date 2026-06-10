extends GutTest

# Integration tests for swing signal handling and sprite animation wiring. Pure state-resolution
# logic is tested in test_paddle_animation_state.gd; this file tests that the Paddle wires the
# sprite correctly when the state changes.


class PaddleDouble:
	extends Paddle
	var grounded: bool = true

	func _is_grounded() -> bool:
		return grounded


var _paddle: PaddleDouble
var _sprite: AnimatedSprite2D


func before_each() -> void:
	_paddle = PaddleDouble.new()

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


# Sets grounded and per-frame vertical motion, then resolves the state as a physics frame would.
func _state(grounded: bool, vertical_motion: float) -> void:
	_paddle.grounded = grounded
	_paddle._vertical_motion = vertical_motion
	_paddle._update_animation_state()


func test_swing_plays_animation_while_grounded() -> void:
	_paddle.grounded = true
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_grounded")


func test_swing_plays_animation_while_flying() -> void:
	_paddle.grounded = false
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_flying")


func test_swing_resumes_grounded_state_after_finish() -> void:
	_paddle.grounded = true
	_paddle.on_ball_hit()
	_sprite.animation_finished.emit()
	assert_eq(_sprite.animation, &"ready_grounded")


func test_swing_resumes_flying_state_after_finish() -> void:
	_state(false, 100.0)
	_paddle.on_ball_hit()
	_sprite.animation_finished.emit()
	assert_eq(_sprite.animation, &"flying_down", "resumes the live flying state after swing")
