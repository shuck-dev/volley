class_name Paddle
extends CharacterBody2D

@warning_ignore("unused_signal")
signal paddle_hit

@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
@export var sprite: Sprite2D
@export var tracker: HitTracker

var _item_manager: Node

var _lane_x := 0.0
var _paddle_speed: float = 0.0
var _collision_shape: RectangleShape2D
var _sprite_natural_height := 0.0


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager

	_lane_x = position.x
	_paddle_speed = _item_manager.get_stat(&"paddle_speed")
	_item_manager.item_level_changed.connect(_on_item_level_changed)

	if collision != null:
		_collision_shape = RectangleShape2D.new()
		_collision_shape.size = collision.shape.size
		collision.shape = _collision_shape

	if sprite != null:
		_sprite_natural_height = sprite.get_rect().size.y

	_apply_size()


func on_ball_hit() -> void:
	if not tracker.try_hit():
		return

	hit_sound.pitch_scale = 1.0 + (tracker.streak * 0.05)
	hit_sound.play()
	paddle_hit.emit()


func reset_streak() -> void:
	tracker.reset()


func drive(velocity_y: float) -> void:
	velocity = Vector2(0.0, velocity_y)
	move_and_slide()
	position.x = _lane_x


func get_speed() -> float:
	return _paddle_speed


func _on_item_level_changed(_item_key: String) -> void:
	_apply_size()
	_paddle_speed = _item_manager.get_stat(&"paddle_speed")


func _apply_size() -> void:
	if _collision_shape == null:
		return

	var arena_height: float = _item_manager.get_stat(&"arena_height")
	var paddle_size_min: float = _item_manager.get_stat(&"paddle_size_min")
	var new_size: float = clampf(
		_item_manager.get_stat(&"paddle_size"), paddle_size_min, arena_height
	)

	_collision_shape.size.y = new_size

	if sprite != null and _sprite_natural_height > 0.0:
		sprite.scale.y = new_size / _sprite_natural_height
