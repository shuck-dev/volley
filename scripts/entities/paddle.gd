class_name Paddle
extends CharacterBody2D

## Emits the ball that triggered the hit.
signal paddle_hit(ball: Ball)

## Top of the paddle's vertical travel.
@export var top_y: float = -540.0

## Played on a successful hit.
@export var hit_sound: AudioStreamPlayer

@export var sprite: AnimatedSprite2D
@export var tracker: HitTracker

## Hitbox to trigger ball bounce.
@export var racket_hitbox: RacketHitbox

## Semicircular trigger around the racket hitbox; starts the swing early so its contact frame lands on time.
@export var swing_zone: Area2D

## Detects the court floor; null falls back to CharacterBody2D.is_on_floor().
@export var ground_ray: RayCast2D

## Suppresses input for auto-play.
var input_blocked: bool = false

var _ball_manager: BallManager

var _lane_x: float = 0.0
var _paddle_speed: float = 0.0

var _animation_controller: PaddleAnimationController


func _ready() -> void:
	_lane_x = position.x
	_paddle_speed = _resolved_paddle_speed()
	_bind_stat_updates()

	racket_hitbox.body_entered.connect(_on_racket_body_entered)

	if swing_zone != null:
		swing_zone.body_entered.connect(_on_swing_zone_entered)

	_animation_controller = (load("res://scripts/core/paddle_animation_controller.gd").new(
		global_position.y
	))
	_animation_controller.state_changed.connect(_on_animation_state_changed)
	sprite.animation_finished.connect(_on_swing_finished)

	# Resolve and play the real state on the first frame, so the sprite matches grounded/flying
	# from load rather than sitting on a default or the scene's authored animation.
	_update_animation_state()

	paddle_hit.connect(_on_paddle_hit_for_swing)


func _physics_process(delta: float) -> void:
	_physics_move(delta)
	tick_animation_state()


func _physics_move(_delta: float) -> void:
	pass


# --- movement and bounds ---


func drive(velocity_y: float) -> void:
	if velocity_y > 0.0 and is_grounded():
		velocity = Vector2.ZERO
		return

	velocity = Vector2(0.0, velocity_y)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()


func clamp_to_arena() -> void:
	position.y = maxf(position.y, get_top_bound_y())


func get_top_bound_y() -> float:
	return top_y + get_half_height()


func is_grounded() -> bool:
	return ground_ray.is_colliding()


func get_speed() -> float:
	return _paddle_speed


func _resolved_paddle_speed() -> float:
	return GameRules.paddle.paddle_speed


func _bind_stat_updates() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager
	_ball_manager.item_level_changed.connect(_refresh_from_stats.unbind(1))
	_ball_manager.item_placement_changed.connect(_refresh_from_stats.unbind(2))


func _refresh_from_stats() -> void:
	_paddle_speed = _resolved_paddle_speed()


# --- shape and hitbox ---


## Hits the ball.
func hit(ball: Ball) -> void:
	if ball.freeze:
		return

	if tracker.try_hit():
		hit_sound.play()
		paddle_hit.emit(ball)

		ball.hit()

	_hit_ball(ball)


func _on_racket_body_entered(body: Node) -> void:
	if body is Ball:
		var ball := body as Ball
		if _lane_x * ball.linear_velocity.x <= 0:
			return
		hit(ball)


func _hit_ball(ball: Ball) -> void:
	ball.refresh_scaled_speed()

	var direction: Variant = (
		PaddleBounceMath
		. bounce_direction(
			ball.linear_velocity,
			ball.global_position,
			global_position,
			get_half_height(),
			GameRules.paddle.paddle_return_angle_max_degrees,
		)
	)

	if direction == null:
		return

	ball.linear_velocity = (direction as Vector2) * ball.scaled_speed


## The normalised denominator for contact-offset return angle.
func get_half_height() -> float:
	return racket_hitbox.get_half_height()


# --- animation ---


func tick_animation_state() -> void:
	_update_animation_state()


func get_movement_state() -> StringName:
	return _animation_controller.get_state()


func _update_animation_state() -> void:
	_animation_controller.tick(global_position.y, is_grounded(), _is_crouching())


func _is_crouching() -> bool:
	return false


## Wired to the animation controller's state_changed signal; plays the animation when it changes.
func _on_animation_state_changed(state: StringName) -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(state):
		sprite.play(state)


## Starts the swing early enough for its contact frame to land on the ball's actual arrival.
func _on_swing_zone_entered(body: Node) -> void:
	if not (body is Ball):
		return

	var ball := body as Ball
	if _lane_x * ball.linear_velocity.x <= 0:
		return

	var speed_scale: float = (
		_animation_controller
		. compute_zone_entry_speed_scale(
			ball.global_position,
			ball.linear_velocity,
			racket_hitbox.global_position,
			is_grounded(),
			_is_crouching(),
		)
	)
	if speed_scale < 0.0:
		return

	sprite.speed_scale = speed_scale
	_animation_controller.start_swing(is_grounded(), _is_crouching())


## Handles the paddle_hit signal to initiate the swing animation, unless anticipation already did.
func _on_paddle_hit_for_swing(_ball: Ball) -> void:
	if _animation_controller.is_swing_pending():
		return

	_animation_controller.start_swing(is_grounded(), _is_crouching())


## Clears the swing pending state and resets playback speed when the animation finishes.
func _on_swing_finished() -> void:
	sprite.speed_scale = 1.0
	_animation_controller.finish_swing(is_grounded(), _is_crouching())
