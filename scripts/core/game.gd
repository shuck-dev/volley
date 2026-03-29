class_name Game
extends Node2D

signal volley_count_changed(count: int)
signal personal_volley_best_changed(best: int)
signal friendship_point_balance_changed(friendship_point_balance: int)
signal ball_at_max_speed_changed(is_at_max: bool)

@export var ball: RigidBody2D
@export var paddle: Node

var _volley_count := 0
var _progression: ProgressionData


func _ready() -> void:
	# Allows direct injection of progression for tests
	if _progression == null:
		_progression = SaveManager.get_progression_data()

	paddle.paddle_hit.connect(_on_paddle_hit)
	ball.missed.connect(_on_ball_missed)
	ball.at_max_speed_changed.connect(ball_at_max_speed_changed.emit)

	friendship_point_balance_changed.emit(_progression.friendship_point_balance)
	personal_volley_best_changed.emit(_progression.personal_volley_best)


func _on_paddle_hit() -> void:
	_volley_count += 1
	_progression.friendship_point_balance += 1

	if _volley_count > _progression.personal_volley_best:
		_progression.personal_volley_best = _volley_count
		personal_volley_best_changed.emit(_progression.personal_volley_best)

	volley_count_changed.emit(_volley_count)
	friendship_point_balance_changed.emit(_progression.friendship_point_balance)
	ball.increase_speed()


func _on_ball_missed() -> void:
	_volley_count = 0
	volley_count_changed.emit(_volley_count)
	ball.reset_speed()
	paddle.reset_streak()
