extends CharacterBody2D

signal paddle_hit

@export var hit_sound: AudioStreamPlayer

var _streak := 0
var _hit_cooldown := 0.0


func _physics_process(delta: float) -> void:
	if _hit_cooldown > 0.0:
		_hit_cooldown -= delta
	var direction := Input.get_axis("paddle_up", "paddle_down")
	velocity.y = direction * GameRules.PADDLE_SPEED
	move_and_slide()


func on_ball_hit() -> void:
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = 0.2
	_streak += 1
	hit_sound.pitch_scale = 1.0 + (_streak * 0.05)
	hit_sound.play()
	paddle_hit.emit()


func reset_streak() -> void:
	_streak = 0
