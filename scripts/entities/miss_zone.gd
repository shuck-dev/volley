extends StaticBody2D

## Attach to any body that should trigger a miss when the ball contacts it.
## The ball detects this via has_method("on_ball_missed").


func on_ball_missed(_ball: Node) -> void:
	pass
