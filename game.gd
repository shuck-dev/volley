extends Node2D

@export var ball: RigidBody2D
@export var hud: CanvasLayer

var _volley_count := 0


func _ready() -> void:
	print("game ready")
	ball.paddle_hit.connect(_on_paddle_hit)


func _on_paddle_hit() -> void:
	_volley_count += 1
	hud.update_volley_count(_volley_count)
