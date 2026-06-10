class_name ConsolidationCue
extends CPUParticles2D


## Replays the one-shot star burst. The node lives in ball.tscn and is re-fired on each
## tier consolidation rather than spawned, so a single instance serves every advance.
func fire() -> void:
	restart()
	emitting = true


## Signal-shaped adapter wired in ball.tscn from the ball's tier_advanced signal.
func _on_ball_tier_advanced(_ball: Ball, _new_tier: int) -> void:
	fire()
