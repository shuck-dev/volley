extends GutTest


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


func test_hit_while_grounded_wires_swing_animation() -> void:
	_paddle.grounded = true
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_grounded")


func test_hit_while_flying_wires_swing_animation() -> void:
	_paddle.grounded = false
	_paddle.on_ball_hit()
	assert_eq(_sprite.animation, &"swing_flying")


func test_animation_finished_after_grounded_hit_resumes_ready() -> void:
	_paddle.grounded = true
	_paddle.on_ball_hit()
	_sprite.animation_finished.emit()
	assert_eq(_sprite.animation, &"ready_grounded")


func test_animation_finished_after_flying_hit_resumes_flying_state() -> void:
	_paddle.grounded = false
	_paddle._vertical_motion = 100.0
	_paddle.on_ball_hit()
	_sprite.animation_finished.emit()
	assert_eq(_sprite.animation, &"flying_down")
