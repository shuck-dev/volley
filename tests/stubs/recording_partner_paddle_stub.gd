extends Node2D

## Records balls passed to set_ball() so tests can assert partner re-targeting.

var last_ball: Node = null
var balls_received: Array[Node] = []


func set_ball(value: Node) -> void:
	last_ball = value
	balls_received.append(value)
