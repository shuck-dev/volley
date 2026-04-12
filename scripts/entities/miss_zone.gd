extends StaticBody2D

## Attach to any body that should trigger a miss when the ball contacts it.
## The ball detects this via has_method("on_ball_missed").
## Set active to false to make the wall bounce instead of triggering a miss.

var active := true


func on_ball_missed(_ball: Node) -> void:
	pass


func is_miss_zone() -> bool:
	return active
