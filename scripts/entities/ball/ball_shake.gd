class_name BallShake
extends Node

## Sprite jitter on consolidation.

@export var sprite: Sprite2D
@export var amplitude := 8.0
@export var duration := 0.15

var _elapsed := -1.0


func _on_ball_tier_advanced(_ball: Ball, _new_tier: int) -> void:
	shake()


func shake() -> void:
	if sprite == null:
		return

	_elapsed = 0.0


func _physics_process(delta: float) -> void:
	if sprite == null or _elapsed < 0.0:
		return

	_elapsed += delta
	if _elapsed >= duration:
		_elapsed = -1.0
		sprite.position = Vector2.ZERO
		return

	var buildup := _elapsed / duration
	sprite.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amplitude * buildup
