class_name ParabolicArcPhysics
extends CourtPhysics


## Parabolic arc IS engine gravity acting on a body with gravity_scale = 1; the rule body is
## intentionally empty. The seam exists so future venues can plug in alternative rules.
func step(_ball: RigidBody2D, _config: CourtConfig, _delta: float) -> void:
	pass
