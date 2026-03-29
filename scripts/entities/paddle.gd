extends CharacterBody2D

signal paddle_hit

@export var hit_sound: AudioStreamPlayer
@export var collision: CollisionShape2D
@export var sprite: Sprite2D

var tracker := HitTracker.new()

var _upgrade_manager: Node
var _lane_x := 0.0


func _ready() -> void:
	if _upgrade_manager == null:
		_upgrade_manager = UpgradeManager
	_lane_x = position.x
	_apply_size()


func _physics_process(delta: float) -> void:
	tracker.process(delta)
	var direction := Input.get_axis("paddle_up", "paddle_down")
	velocity = Vector2(0.0, direction * _upgrade_manager.get_value(UpgradeManager.PADDLE_SPEED_KEY))
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


func _apply_size() -> bool:
	if collision == null:
		return false

	var base_size: float = collision.shape.size.y
	var new_size: float = _upgrade_manager.get_value(UpgradeManager.PADDLE_SIZE_KEY)

	collision.shape.size.y = new_size

	if sprite != null:
		sprite.scale.y = new_size / base_size

	return true
