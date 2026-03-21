extends Node2D

var _volley_count: int = 0


func _ready() -> void:
	$Ball.paddle_hit.connect(_on_paddle_hit)


func _on_paddle_hit() -> void:
	_volley_count += 1
	$CanvasLayer/Label.text = "Volleys: %d" % _volley_count
