class_name Paddle
extends CharacterBody2D

@warning_ignore("unused_signal")
signal paddle_hit

# Upper limit only; the venue floor handles the bottom physically.
# Tuned high enough to chase arcing balls into PLAY-ARC, low enough to stay on-screen.
const PADDLE_TOP_Y := -540.0

@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
@export var sprite: Sprite2D
@export var tracker: HitTracker

## Set by TimeoutController during the walk; suppresses drive() so controllers don't fight the pose.
var drive_blocked: bool = false

var _item_manager: Node

var _lane_x := 0.0
var _paddle_speed: float = 0.0
var _collision_shape: RectangleShape2D
var _sprite_natural_height := 0.0

# False until the first _apply_size lands; the initial call is sizing, not a resize.
var _size_initialised: bool = false


func _ready() -> void:
	add_to_group(&"paddles")
	_lane_x = position.x
	_paddle_speed = _resolved_paddle_speed()
	_bind_stat_updates()

	if collision != null:
		_collision_shape = RectangleShape2D.new()
		_collision_shape.size = collision.shape.size
		collision.shape = _collision_shape

	if sprite != null:
		_sprite_natural_height = sprite.get_rect().size.y

	_apply_size()


func on_ball_hit() -> bool:
	if not tracker.try_hit():
		return false

	hit_sound.pitch_scale = 1.0 + (tracker.streak * 0.05)
	hit_sound.play()
	paddle_hit.emit()
	return true


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


func get_speed() -> float:
	return _paddle_speed


# Half of the collider's vertical extent; the normalised denominator for contact-offset return angle.
func get_half_height() -> float:
	if _collision_shape == null:
		return 0.0
	return _collision_shape.size.y * 0.5


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
	_apply_size()
	_paddle_speed = _resolved_paddle_speed()


func _apply_size() -> void:
	if _collision_shape == null:
		return

	var arena_height: float = _resolve(GameRules.base.arena_height, &"arena_height")
	var paddle_size_min: float = _resolve(GameRules.paddle.paddle_size_min, &"paddle_size_min")
	var paddle_size: float = _resolve(GameRules.paddle.paddle_size, &"paddle_size")
	var new_size: float = clampf(paddle_size, paddle_size_min, arena_height)

	# Anchor the collider's foot: RectangleShape2D is centred on the body, so growing size.y without
	# shifting position.y plants half the delta below the floor and traps depenetration during AT_EQUIP_POSE.
	var old_size: float = _collision_shape.size.y
	if _size_initialised and is_equal_approx(new_size, old_size):
		return
	_collision_shape.size.y = new_size
	if _size_initialised:
		position.y -= (new_size - old_size) * 0.5
	_size_initialised = true

	if sprite != null and _sprite_natural_height > 0.0:
		sprite.scale.y = new_size / _sprite_natural_height
