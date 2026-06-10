class_name Paddle
extends CharacterBody2D

## Emits the ball that triggered the hit; null when emitted without a ball context (e.g. tests).
signal paddle_hit(ball: Ball)

const PADDLE_TOP_Y := -540.0
## Slack in pixels for the grounded test; the foot counts as on the floor within this of the surface.
const GROUNDED_EPSILON := 2.0
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

## Set by TimeoutController during the walk; suppresses drive() so controllers don't fight the pose.
var drive_blocked: bool = false

var _item_manager: Node

var _lane_x: float = 0.0
var _paddle_speed: float = 0.0
var _collision_shape: RectangleShape2D

# False until the first _apply_size lands; the initial call is sizing, not a resize.
var _size_initialised: bool = false

var _current_state: StringName = &"ready_grounded"
var _swing_pending: bool = false

## World Y of the floor's top surface, resolved at ready from the floor group. NAN until found.
var _floor_surface_y: float = NAN

var _sprite_width_scale: float = 1.0
var _collider_overlay: ColliderOverlay
var _state_label: Label


func _ready() -> void:
	add_to_group(&"paddles")
	_lane_x = position.x
	_paddle_speed = _resolved_paddle_speed()
	_bind_stat_updates()

	if collision != null:
		_collision_shape = RectangleShape2D.new()
		_collision_shape.size = collision.shape.size
		collision.shape = _collision_shape

	_fit_body_to_sprite()

	if racket_hitbox != null:
		racket_hitbox.body_entered.connect(_on_racket_body_entered)

	_resolve_floor_surface()

	_collider_overlay = ColliderOverlay.new()
	_collider_overlay.z_index = 100
	add_child(_collider_overlay)

	_setup_state_label()

	# Play the initial state's animation so the sprite matches the FSM from the first frame,
	# rather than sitting on whatever the scene authored as the default animation.
	if sprite != null:
		sprite.play(_current_state)

	paddle_hit.connect(_on_paddle_hit_for_swing)


func on_ball_hit(ball: Ball = null) -> bool:
	if not tracker.try_hit():
		return false

	hit_sound.pitch_scale = 1.0 + (tracker.streak * 0.05)
	hit_sound.play()
	paddle_hit.emit(ball)
	return true


# The ball entered the racket zone; route it to the ball's hit entry. The ball passes through
# the character body, so the racket Area2D is now the sole paddle-hit trigger.
func _on_racket_body_entered(body: Node) -> void:
	if body is Ball:
		(body as Ball).hit_by_paddle(self)


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
	if _collision_shape != null:
		half_height = _collision_shape.size.y * 0.5 + STATE_LABEL_GAP
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

	velocity = Vector2(0.0, velocity_y)
	move_and_slide()
	position.x = _lane_x
	clamp_to_arena()


func clamp_to_arena() -> void:
	position.y = maxf(position.y, PADDLE_TOP_Y + get_half_height())


# The animation state tracks grounded/flying and motion every physics frame, not just when a
# controller calls drive(), so a grounded/flying transition updates the moment it happens.
func _physics_process(_delta: float) -> void:
	_update_animation_state()


func get_speed() -> float:
	return _paddle_speed


# Half of the racket zone's vertical extent; the normalised denominator for contact-offset return
# angle. The racket, not the wall body, defines where on the paddle the ball is judged to strike.
func get_half_height() -> float:
	if racket_shape != null and racket_shape.shape is RectangleShape2D:
		return (racket_shape.shape as RectangleShape2D).size.y * 0.5
	if _collision_shape == null:
		return 0.0
	return _collision_shape.size.y * 0.5


func get_movement_state() -> StringName:
	return _current_state


# Finds the floor (a StaticBody in the "floor" group) and records its top-surface world Y. The paddle
# slides on a code-clamped lane with no gravity, so is_on_floor() is unreliable; grounded is a
# position test against this line instead. Leaves _floor_surface_y as NAN if no floor is present.
func _resolve_floor_surface() -> void:
	var floors: Array = get_tree().get_nodes_in_group(&"floor")
	if floors.is_empty():
		return
	var floor_body: Node2D = floors[0] as Node2D
	if floor_body == null:
		return
	var half: float = 0.0
	for child in floor_body.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			half = ((child as CollisionShape2D).shape as RectangleShape2D).size.y * 0.5
			break
	_floor_surface_y = floor_body.global_position.y - half


# Grounded when the paddle's foot (centre plus half-height) has reached the floor surface. With no
# resolved floor line (no floor in the scene, e.g. a bare unit test) the paddle is treated as flying.
func _is_grounded() -> bool:
	if is_nan(_floor_surface_y):
		return false
	return global_position.y + get_half_height() >= _floor_surface_y - GROUNDED_EPSILON


# Resolves the animation state from grounded/flying, vertical motion, and the swing overlay. Swing
# wins: swinging plays swing_grounded/swing_flying. Otherwise a flying paddle plays flying_up/
# flying_down while it moves vertically and ready_flying when still; grounded plays ready_grounded.
func _update_animation_state() -> void:
	var grounded: bool = _is_grounded()
	var new_state: StringName

	if _swing_pending:
		new_state = &"swing_grounded" if grounded else &"swing_flying"
	elif grounded:
		new_state = &"ready_grounded"
	elif not is_zero_approx(velocity.y):
		new_state = &"flying_up" if velocity.y < 0.0 else &"flying_down"
	else:
		new_state = &"ready_flying"

	if new_state == _current_state:
		return
	_current_state = new_state
	if sprite != null:
		sprite.play(new_state)


func _on_paddle_hit_for_swing(_ball: Ball) -> void:
	_swing_pending = true
	_update_animation_state()

	if sprite != null and not sprite.animation_finished.is_connected(_on_swing_finished):
		sprite.animation_finished.connect(_on_swing_finished, CONNECT_ONE_SHOT)


func _on_swing_finished() -> void:
	_swing_pending = false
	_update_animation_state()


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
	_fit_body_to_sprite()


func set_sprite_width_scale(factor: float) -> void:
	_sprite_width_scale = factor
	if sprite == null:
		return
	sprite.scale.x = factor
	_fit_body_to_sprite()


# Sizes the wall body to the sprite's on-screen dimensions (frame size times scale), foot-anchored,
# so the character collides with walls and floor across its visible body. The body tracks the sprite,
# not paddle_size; scrubbing the sprite size moves the wall collider with it.
func _fit_body_to_sprite() -> void:
	if _collision_shape == null or sprite == null:
		return
	if sprite.sprite_frames == null or sprite.sprite_frames.get_frame_count(sprite.animation) == 0:
		return
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if frame == null:
		return
	var new_size := Vector2(frame.get_width() * sprite.scale.x, frame.get_height() * sprite.scale.y)
	var old_height: float = _collision_shape.size.y
	_collision_shape.size = new_size
	if _size_initialised:
		position.y -= (new_size.y - old_height) * 0.5
	_size_initialised = true
	_refresh_overlay_shapes()


# Sets the racket zone's horizontal position, live-tunable from the dev panel.
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
	if racket_shape != null and racket_shape.shape is RectangleShape2D:
		var rect := racket_shape.shape as RectangleShape2D
		rect.size.x = width
	_refresh_overlay_shapes()


# Sets the racket zone's height, live-tunable from the dev panel.
func set_racket_height(height: float) -> void:
	if racket_shape != null and racket_shape.shape is RectangleShape2D:
		var rect := racket_shape.shape as RectangleShape2D
		rect.size.y = height
	_refresh_overlay_shapes()


# Toggles the body-collider overlay independently of the racket, drawn above the sprite.
func set_body_collider_visible(shown: bool) -> void:
	if _collider_overlay == null:
		return
	_refresh_overlay_shapes()
	_collider_overlay.set_body_active(shown)


# Toggles the racket-collider overlay independently of the body, drawn above the sprite.
func set_racket_collider_visible(shown: bool) -> void:
	if _collider_overlay == null:
		return
	_refresh_overlay_shapes()
	_collider_overlay.set_racket_active(shown)


func _refresh_overlay_shapes() -> void:
	if _collider_overlay == null:
		return
	var body_size: Vector2 = _collision_shape.size if _collision_shape != null else Vector2.ZERO
	var racket_size: Vector2 = Vector2.ZERO
	var racket_offset: Vector2 = Vector2.ZERO
	if racket_shape != null and racket_shape.shape is RectangleShape2D:
		racket_size = (racket_shape.shape as RectangleShape2D).size
		racket_offset = racket_hitbox.position if racket_hitbox != null else Vector2.ZERO
	_collider_overlay.set_shapes(body_size, racket_size, racket_offset)
