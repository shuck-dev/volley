class_name ConsolidationCue
extends CPUParticles2D


## Replays the one-shot star burst from this single reused instance.
func fire() -> void:
	restart()
	emitting = true


## Signal-shaped adapter wired in ball.tscn from the ball's tier_advanced signal.
func _on_ball_tier_advanced(_ball: Ball, _new_tier: int) -> void:
	fire()
