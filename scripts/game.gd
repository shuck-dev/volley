class_name Game
extends Node2D

signal volley_count_changed(count: int)
signal personal_best_changed(best: int)
signal friendship_total_changed(friendship_total: int)

@export var ball: RigidBody2D
@export var paddle: Node

var _volley_count := 0
var _personal_volley_best := 0
var _friendship_total := 0


func _ready() -> void:
	paddle.paddle_hit.connect(_on_paddle_hit)
	ball.missed.connect(_on_ball_missed)


func _on_paddle_hit() -> void:
	_volley_count += 1
	_friendship_total += 1

	if _volley_count > _personal_volley_best:
		_personal_volley_best = _volley_count
		personal_best_changed.emit(_personal_volley_best)

	volley_count_changed.emit(_volley_count)
	friendship_total_changed.emit(_friendship_total)
	ball.increase_speed()


func _on_ball_missed() -> void:
	_volley_count = 0
	volley_count_changed.emit(_volley_count)
	ball.reset_speed()
	paddle.reset_streak()
