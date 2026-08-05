class_name Paddle
extends CharacterBody2D

## Emits the ball that triggered the hit; null when emitted without a ball context (e.g. tests).
signal paddle_hit(ball: Ball)

const PADDLE_TOP_Y := -540.0


class MovementState:
	var lane_x: float = 0.0
	var paddle_speed: float = 0.0


class ShapeCache:
	var body_shape: RectangleShape2D
	var racket_shape: RectangleShape2D


@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
@export var sprite: AnimatedSprite2D
@export var tracker: HitTracker
## Mid-body Area2D that detects the ball; the racket zone, separate from the wall body.
@export var racket_hitbox: Area2D
## The racket's RectangleShape2D, owning the contact-offset half-height.
@export var racket_shape: CollisionShape2D
@export var ground_ray: RayCast2D

## Set by AutoplayController during autoplay; suppresses _physics_move input so PlayerPaddle
## does not clobber the AI driver's velocity with Input.get_axis defaults.
var input_blocked: bool = false

var _ball_manager: BallManager

var _movement := MovementState.new()
var _shape := ShapeCache.new()

var _animation_controller: PaddleAnimationController


func _ready() -> void:
	_movement.lane_x = position.x
	_movement.paddle_speed = _resolved_paddle_speed()
	_bind_stat_updates()

	if collision.shape is RectangleShape2D:
		_shape.body_shape = collision.shape

	if racket_shape.shape is RectangleShape2D:
		_shape.racket_shape = racket_shape.shape

	racket_hitbox.body_entered.connect(_on_racket_body_entered)

	collision.disabled = true

	_ensure_animation_controller()
	_animation_controller.start(global_position.y)

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
	position.x = _movement.lane_x
	clamp_to_arena()


func clamp_to_arena() -> void:
	position.y = maxf(position.y, get_top_bound_y())


func get_top_bound_y() -> float:
	return PADDLE_TOP_Y + get_half_height()


func is_grounded() -> bool:
	if ground_ray == null:
		return super.is_on_floor()
	return ground_ray.is_colliding()


func get_speed() -> float:
	return _movement.paddle_speed


func _resolved_paddle_speed() -> float:
	return GameRules.paddle.paddle_speed


func _bind_stat_updates() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager
	_ball_manager.item_level_changed.connect(_refresh_from_stats.unbind(1))
	_ball_manager.item_placement_changed.connect(_refresh_from_stats.unbind(2))


func _refresh_from_stats() -> void:
	_movement.paddle_speed = _resolved_paddle_speed()


# --- shape and hitbox ---


func on_ball_hit(ball: Ball = null) -> bool:
	if not tracker.try_hit():
		return false

	hit_sound.play()
	paddle_hit.emit(ball)
	return true


func _on_racket_body_entered(body: Node) -> void:
	if body is Ball:
		var ball := body as Ball
		if _movement.lane_x * ball.linear_velocity.x <= 0:
			return
		ball.hit_by_paddle(self)


# Half of the racket zone's vertical extent; the normalised denominator for contact-offset return
# angle. The racket, not the wall body, defines where on the paddle the ball is judged to strike.
func get_half_height() -> float:
	if _shape.racket_shape != null:
		return _shape.racket_shape.size.y * 0.5
	return 0.0


func set_racket_width(width: float) -> void:
	if _shape.racket_shape != null:
		_shape.racket_shape.size.x = width


func set_racket_height(height: float) -> void:
	if _shape.racket_shape != null:
		_shape.racket_shape.size.y = height


func set_body_collision_enabled(enabled: bool) -> void:
	collision.disabled = not enabled


# --- animation ---


func tick_animation_state() -> void:
	_update_animation_state()


func get_movement_state() -> StringName:
	_ensure_animation_controller()
	return _animation_controller.get_state()


func _is_crouching() -> bool:
	return false


func _ensure_animation_controller() -> void:
	if _animation_controller == null:
		_animation_controller = load("res://scripts/core/paddle_animation_controller.gd").new()
		_animation_controller.state_changed.connect(_on_animation_state_changed)


func _update_animation_state() -> void:
	_ensure_animation_controller()
	_animation_controller.tick(global_position.y, is_grounded(), _is_crouching())


## Wired to the animation controller's state_changed signal; plays the animation when it changes.
func _on_animation_state_changed(state: StringName) -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(state):
		sprite.play(state)


## Handles the paddle_hit signal to initiate the swing animation.
func _on_paddle_hit_for_swing(_ball: Ball) -> void:
	_ensure_animation_controller()
	_animation_controller.on_hit(is_grounded(), _is_crouching())

	if not sprite.animation_finished.is_connected(_on_swing_finished):
		sprite.animation_finished.connect(_on_swing_finished, CONNECT_ONE_SHOT)


## Clears the swing pending state when the animation finishes.
func _on_swing_finished() -> void:
	if _animation_controller == null:
		return

	_animation_controller.on_swing_finished(is_grounded(), _is_crouching())
