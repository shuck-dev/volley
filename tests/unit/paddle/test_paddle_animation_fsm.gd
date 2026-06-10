extends GutTest

# The animation state resolves from grounded/flying, vertical motion, and the swing overlay, with
# swing winning. The double overrides _is_grounded (the paddle's own method) so grounded is
# controllable without a floor in the scene; velocity.y is set directly to drive the motion states.


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


# Sets grounded and vertical velocity, then resolves the state as a physics frame would.
func _state(grounded: bool, velocity_y: float) -> void:
	_paddle.grounded = grounded
	_paddle.velocity = Vector2(0.0, velocity_y)
	_paddle._update_animation_state()


# --- grounded ready ---


func test_starts_ready_grounded() -> void:
	assert_eq(_paddle.get_movement_state(), &"ready_grounded")


func test_grounded_still_is_ready_grounded() -> void:
	_state(true, 0.0)
	assert_eq(_sprite.animation, &"ready_grounded")


# --- flying motion ---


func test_flying_upward_is_flying_up() -> void:
	_state(false, -100.0)
	assert_eq(_sprite.animation, &"flying_up")


func test_flying_downward_is_flying_down() -> void:
	_state(false, 100.0)
	assert_eq(_sprite.animation, &"flying_down")


func test_flying_still_is_ready_flying() -> void:
	_state(false, 0.0)
	assert_eq(_sprite.animation, &"ready_flying")


func test_returning_to_floor_is_ready_grounded() -> void:
	_state(false, -100.0)
	_state(true, 0.0)
	assert_eq(_sprite.animation, &"ready_grounded")


# --- swing wins ---


func test_swing_while_grounded_is_swing_grounded() -> void:
	_paddle.grounded = true
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_grounded")


func test_swing_while_flying_is_swing_flying() -> void:
	_paddle.grounded = false
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_flying")


func test_swing_overrides_flying_motion() -> void:
	_state(false, 100.0)
	assert_eq(_sprite.animation, &"flying_down")
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_flying", "swing wins over flying_down")


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
