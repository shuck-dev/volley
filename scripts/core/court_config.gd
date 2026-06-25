## Per-court tunables: court width, fair-crossing time, and the above-bound arc rule.
class_name CourtConfig
extends Resource

## Full paddle-to-paddle court span in pixels; the world speed max derives from it.
@export var court_width: float = 1500.0
## Seconds a fair crossing must outlast so the receiver can move and react; sets the world speed max against the crossing.
@export var fair_crossing_seconds: float = 2.083333
## Above-bound arc rule. Swap per venue to change how the ball arcs over the soul bound.
@export var physics: CourtPhysics = load("res://scripts/core/court_physics.gd").new()


## Top speed any ball may reach, derived from the court crossing: court_width / fair_crossing_seconds.
func world_max_speed() -> float:
	return court_width / fair_crossing_seconds
