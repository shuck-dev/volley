class_name CourtPhysics
extends Resource


## Per-tick hook for the above-bound (PLAY-ARC) physics rule. Default is a no-op so a missing
## or null physics resource degrades to engine-gravity-only behaviour without crashing.
func step(_ball: RigidBody2D, _config: CourtConfig, _delta: float) -> void:
	pass
