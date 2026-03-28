extends CharacterBody2D

signal paddle_hit

@export var hit_sound: AudioStreamPlayer

var tracker := HitTracker.new()
var _lane_x := 0.0


func _ready() -> void:
	_lane_x = position.x


func _physics_process(delta: float) -> void:
	tracker.process(delta)
	var direction := Input.get_axis("paddle_up", "paddle_down")
	velocity = Vector2(0.0, direction * GameRules.PADDLE_SPEED)
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
