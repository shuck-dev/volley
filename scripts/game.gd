extends Node2D

@export var ball: RigidBody2D
@export var hud: CanvasLayer
@export var paddle: Node

var _volley_count := 0
var _personal_volley_best := 0


func _ready() -> void:
	print("game ready")
	paddle.paddle_hit.connect(_on_paddle_hit)
	ball.missed.connect(_on_ball_missed)


func _on_paddle_hit() -> void:
	_volley_count += 1

	if _volley_count > _personal_volley_best:
		_personal_volley_best = _volley_count
		hud.update_personal_volley_best(_personal_volley_best)

	hud.update_volley_count(_volley_count)
	ball.increase_speed()


func _on_ball_missed() -> void:
	_volley_count = 0
	hud.update_volley_count(_volley_count)
	ball.reset_speed()
	paddle.reset_streak()
