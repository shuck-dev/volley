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

## Detects the court floor; null falls back to CharacterBody2D.is_on_floor().
@export var ground_ray: RayCast2D

## Suppresses input for auto-play.
var input_blocked: bool = false

var _ball_manager: BallManager

var _lane_x: float = 0.0
var _paddle_speed: float = 0.0

var _animation_controller: PaddleAnimationController

## Bound so the animation layer can anticipate contact; unset means no anticipation (e.g. AI paddles today).
var _ball_reconciler: BallReconciler


func _ready() -> void:
	_lane_x = position.x
	_paddle_speed = _resolved_paddle_speed()
	_bind_stat_updates()

	racket_hitbox.body_entered.connect(_on_racket_body_entered)

	_animation_controller = (load("res://scripts/core/paddle_animation_controller.gd").new(
		global_position.y
	))
	_animation_controller.state_changed.connect(_on_animation_state_changed)

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


func on_ball_hit(ball: Ball = null) -> bool:
	if not tracker.try_hit():
		return false

	hit_sound.play()
	paddle_hit.emit(ball)
	return true


func _on_racket_body_entered(body: Node) -> void:
	if body is Ball:
		var ball := body as Ball
		if _lane_x * ball.linear_velocity.x <= 0:
			return
		ball.hit_by_paddle(self)


# The normalised denominator for contact-offset return angle.
func get_half_height() -> float:
	return racket_hitbox.get_half_height()


# --- animation ---


## Wires the ball tracker the animation layer polls to anticipate contact; null disables anticipation.
func bind_ball_reconciler(reconciler: BallReconciler) -> void:
	_ball_reconciler = reconciler


func tick_animation_state() -> void:
	_update_animation_state()


func get_movement_state() -> StringName:
	return _animation_controller.get_state()


func _update_animation_state() -> void:
	_animation_controller.tick(global_position.y, is_grounded(), _is_crouching())

	if _ball_reconciler != null:
		# A ball approaches this lane when its velocity opposes the lane's own side of the court.
		var lane_sign: float = -signf(_lane_x)
		_animation_controller.tick_anticipation(_ball_reconciler, _lane_x, lane_sign, is_grounded())


func _is_crouching() -> bool:
	return false


## Wired to the animation controller's state_changed signal; plays the animation when it changes.
func _on_animation_state_changed(state: StringName) -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(state):
		sprite.play(state)


## Handles the paddle_hit signal to initiate the swing animation.
func _on_paddle_hit_for_swing(_ball: Ball) -> void:
	_animation_controller.on_hit(is_grounded(), _is_crouching())

	if not sprite.animation_finished.is_connected(_on_swing_finished):
		sprite.animation_finished.connect(_on_swing_finished, CONNECT_ONE_SHOT)


## Clears the swing pending state when the animation finishes.
func _on_swing_finished() -> void:
	_animation_controller.on_swing_finished(is_grounded(), _is_crouching())
