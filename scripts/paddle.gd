extends RigidBody2D

signal paddle_hit

@export var hit_sound: AudioStreamPlayer

var _start_x: float
var _streak := 0


func _ready() -> void:
	_start_x = position.x
	gravity_scale = 0.0
	linear_damp = 10.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("paddle_up", "paddle_down")
	linear_velocity.y = direction * GameRules.PADDLE_SPEED
	position.x = _start_x  # Lock x position


func on_ball_hit() -> void:
	_streak += 1
	hit_sound.pitch_scale = 1.0 + (_streak * 0.05)
	hit_sound.play()
	paddle_hit.emit()


func reset_streak() -> void:
	_streak = 0
