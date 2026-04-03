class_name Paddle
extends CharacterBody2D

@warning_ignore("unused_signal")
signal paddle_hit

@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
@export var sprite: Sprite2D
@export var tracker: HitTracker

var _item_manager

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


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	velocity = Vector2(0.0, direction * _paddle_speed)
	move_and_slide()
	position.x = _lane_x


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


func _on_item_level_changed(item_key: String) -> void:
	if item_key == "paddle_size":
		_apply_size()
	elif item_key == "paddle_speed":
		_paddle_speed = _item_manager.get_stat(&"paddle_speed")


func _apply_size() -> void:
	if _collision_shape == null:
		return

	var new_size: float = _item_manager.get_stat(&"paddle_size")

	_collision_shape.size.y = new_size

	if sprite != null and _sprite_natural_height > 0.0:
		sprite.scale.y = new_size / _sprite_natural_height
