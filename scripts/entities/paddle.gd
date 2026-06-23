class_name Paddle
extends CharacterBody2D

## Emits the ball that triggered the hit; null when emitted without a ball context (e.g. tests).
signal paddle_hit(ball: Ball)

const PADDLE_TOP_Y := -540.0
## Gap in pixels between the paddle's top edge and the dev state label sitting above it.
const STATE_LABEL_GAP := 8.0

@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
@export var sprite: AnimatedSprite2D
@export var tracker: HitTracker
## Mid-body Area2D that detects the ball; the racket zone, separate from the wall body.
@export var racket_hitbox: Area2D
## The racket's RectangleShape2D, owning the contact-offset half-height.
@export var racket_shape: CollisionShape2D
@export var ground_ray: RayCast2D
@export var bob_amplitude := 10.0
@export var bob_frequency := 3.0

## Set by TimeoutController during the walk; suppresses drive() so controllers don't fight the pose.
var drive_blocked: bool = false

var _item_manager: Node

var _lane_x: float = 0.0
var _paddle_speed: float = 0.0
var _body_shape: RectangleShape2D
var _racket_shape: RectangleShape2D

## Previous frame's Y, used to derive actual vertical motion so the state reflects real movement
## (driven, timeout-controlled, or at rest) rather than the stale velocity member.
var _last_y: float = 0.0
var _vertical_motion: float = 0.0
var _sprite_width_scale: float = 1.0
var _collider_overlay: ColliderOverlay
var _state_label: Label

var _animation_state_machine: RefCounted
var _bob_time := 0.0


func _ready() -> void:
	add_to_group(&"paddles")
	_lane_x = position.x
	_paddle_speed = _resolved_paddle_speed()
	_bind_stat_updates()

	if collision != null and collision.shape is RectangleShape2D:
		_body_shape = collision.shape

	if racket_shape != null and racket_shape.shape is RectangleShape2D:
		_racket_shape = racket_shape.shape

	if racket_hitbox != null:
		racket_hitbox.body_entered.connect(_on_racket_body_entered)

	if ground_ray == null:
		ground_ray = get_node_or_null("GroundRay") as RayCast2D

	if collision != null:
		collision.disabled = true

	_last_y = global_position.y

	_collider_overlay = ColliderOverlay.new()
	_collider_overlay.z_index = 100
	add_child(_collider_overlay)

	_setup_state_label()

	_ensure_animation_state_machine()

	# Resolve and play the real state on the first frame, so the sprite matches grounded/flying
	# from load rather than sitting on a default or the scene's authored animation.
	_update_animation_state()

	paddle_hit.connect(_on_paddle_hit_for_swing)


func on_ball_hit(ball: Ball = null) -> bool:
	if not tracker.try_hit():
		return false

	hit_sound.pitch_scale = 1.0 + (tracker.streak * 0.05)
	hit_sound.play()
	paddle_hit.emit(ball)
	return true


func _on_racket_body_entered(body: Node) -> void:
	if body is Ball:
		var ball := body as Ball
		if _lane_x * ball.linear_velocity.x <= 0:
			return
		ball.hit_by_paddle(self)


# Dev placeholder: labels the live animation state over the coloured sprite, so each blocked-out
# state reads clearly while real art is pending. Updates whenever the sprite's animation changes.
func _setup_state_label() -> void:
	if not OS.is_debug_build() or sprite == null:
		return
	_state_label = Label.new()
	_state_label.z_index = 101
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_color_override(&"font_color", Color.WHITE)
	_state_label.visible = false
	add_child(_state_label)
	sprite.animation_changed.connect(_refresh_state_label)
	_refresh_state_label()


# Toggled from the PlayerSprite dev panel; the state label is off until the player turns it on.
func set_state_label_visible(value: bool) -> void:
	if _state_label != null:
		_state_label.visible = value


# Centres the label horizontally on the paddle and sits it just above the sprite's top edge. Uses
# the body collider half-height, which tracks the sprite, so the label rides above the visible paddle.
func _position_state_label() -> void:
	if _state_label == null:
		return
	var half_height: float = STATE_LABEL_GAP
	if _body_shape != null:
		half_height = _body_shape.size.y * 0.5 + STATE_LABEL_GAP
	_state_label.size = Vector2.ZERO
	var min_size: Vector2 = _state_label.get_minimum_size()
	_state_label.position = Vector2(-min_size.x * 0.5, -half_height - min_size.y)


func _refresh_state_label() -> void:
	if _state_label == null or sprite == null:
		return
	_state_label.text = String(sprite.animation)
	_position_state_label()


func reset_streak() -> void:
	tracker.reset()


func drive(velocity_y: float) -> void:
	if drive_blocked:
		return
	if velocity_y > 0.0 and is_grounded():
		velocity = Vector2.ZERO
		return

	velocity = Vector2(0.0, velocity_y)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()


func clamp_to_arena() -> void:
	position.y = maxf(position.y, PADDLE_TOP_Y + get_half_height())


func _physics_process(delta: float) -> void:
	_physics_move(delta)
	tick_animation_state()
	_bob_time += delta

	if _collider_overlay != null:
		_collider_overlay.tick_ray_draw()

	if sprite != null:
		if is_grounded():
			sprite.position.y = 0.0
		else:
			sprite.position.y = sin(_bob_time * bob_frequency) * bob_amplitude


func _physics_move(_delta: float) -> void:
	pass


func tick_animation_state() -> void:
	_vertical_motion = global_position.y - _last_y
	_last_y = global_position.y
	_update_animation_state()


func get_speed() -> float:
	return _paddle_speed


# Half of the racket zone's vertical extent; the normalised denominator for contact-offset return
# angle. The racket, not the wall body, defines where on the paddle the ball is judged to strike.
func get_half_height() -> float:
	if _racket_shape != null:
		return _racket_shape.size.y * 0.5
	return 0.0


func get_movement_state() -> StringName:
	return _animation_state_machine.get_state()


func is_grounded() -> bool:
	if ground_ray == null:
		return super.is_on_floor()
	return ground_ray.is_colliding()


func _ensure_animation_state_machine() -> void:
	if _animation_state_machine == null:
		_animation_state_machine = (
			load("res://scripts/core/paddle_animation_state_machine.gd").new()
		)
		_animation_state_machine.state_changed.connect(_on_animation_state_changed)


## Updates the animation state machine and plays any new state.
func _update_animation_state() -> void:
	_ensure_animation_state_machine()
	var grounded: bool = is_grounded()
	_animation_state_machine.update(grounded, _vertical_motion, _is_crouching())


## Wired to the machine's state_changed signal; plays the animation when the state changes.
func _on_animation_state_changed(state: StringName) -> void:
	if (
		sprite != null
		and sprite.sprite_frames != null
		and sprite.sprite_frames.has_animation(state)
	):
		sprite.play(state)


## Handles the paddle_hit signal to initiate the swing animation.
func _on_paddle_hit_for_swing(_ball: Ball) -> void:
	_ensure_animation_state_machine()

	var grounded: bool = is_grounded()
	_animation_state_machine.on_hit(grounded, _vertical_motion, _is_crouching())

	if sprite != null and not sprite.animation_finished.is_connected(_on_swing_finished):
		sprite.animation_finished.connect(_on_swing_finished, CONNECT_ONE_SHOT)


## Clears the swing pending state when the animation finishes.
func _on_swing_finished() -> void:
	if _animation_state_machine == null:
		return

	var grounded: bool = is_grounded()
	_animation_state_machine.on_swing_finished(grounded, _vertical_motion)


func _is_crouching() -> bool:
	return false


func _resolved_paddle_speed() -> float:
	return _resolve(GameRules.paddle.paddle_speed, &"paddle_speed")


func _resolve(base: float, key: StringName) -> float:
	if _item_manager == null:
		_item_manager = ItemManager
	return Stats.resolve(base, key, _item_manager)


func _bind_stat_updates() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	_item_manager.item_level_changed.connect(_refresh_from_stats.unbind(1))
	_item_manager.item_placement_changed.connect(_refresh_from_stats.unbind(2))


func _refresh_from_stats() -> void:
	_paddle_speed = _resolved_paddle_speed()


func set_sprite_height_scale(factor: float) -> void:
	if sprite == null:
		return
	sprite.scale.y = factor


func set_sprite_width_scale(factor: float) -> void:
	_sprite_width_scale = factor
	if sprite == null:
		return
	sprite.scale.x = factor


func set_racket_position_x(offset_x: float) -> void:
	if racket_hitbox != null:
		racket_hitbox.position.x = offset_x
	_refresh_overlay_shapes()


# Sets the racket zone's vertical position (mid-body offset), live-tunable from the dev panel.
func set_racket_position_y(offset_y: float) -> void:
	if racket_hitbox != null:
		racket_hitbox.position.y = offset_y
	_refresh_overlay_shapes()


# Sets the racket zone's width, live-tunable from the dev panel.
func set_racket_width(width: float) -> void:
	if _racket_shape != null:
		_racket_shape.size.x = width
	_refresh_overlay_shapes()


# Sets the racket zone's height, live-tunable from the dev panel.
func set_racket_height(height: float) -> void:
	if _racket_shape != null:
		_racket_shape.size.y = height
	_refresh_overlay_shapes()


# Toggles the body-collider overlay independently of the racket, drawn above the sprite.
func set_body_collision_enabled(enabled: bool) -> void:
	if collision != null:
		collision.disabled = not enabled


func set_body_collider_visible(shown: bool) -> void:
	if _collider_overlay == null:
		return
	_refresh_overlay_shapes()
	_collider_overlay.set_body_active(shown)


func set_ground_ray_visible(shown: bool) -> void:
	if _collider_overlay == null:
		return
	_collider_overlay.set_ray_visible(shown, ground_ray)


# Toggles the racket-collider overlay independently of the body, drawn above the sprite.
func set_racket_collider_visible(shown: bool) -> void:
	if _collider_overlay == null:
		return
	_refresh_overlay_shapes()
	_collider_overlay.set_racket_active(shown)


func _refresh_overlay_shapes() -> void:
	if _collider_overlay == null:
		return
	var body_size: Vector2 = _body_shape.size if _body_shape != null else Vector2.ZERO
	var body_offset: Vector2 = collision.position if collision != null else Vector2.ZERO
	var racket_size: Vector2 = _racket_shape.size if _racket_shape != null else Vector2.ZERO
	var racket_offset: Vector2 = racket_hitbox.position if racket_hitbox != null else Vector2.ZERO
	_collider_overlay.set_shapes(body_size, body_offset, racket_size, racket_offset)
