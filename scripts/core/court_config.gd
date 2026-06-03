class_name CourtConfig
extends Resource

## Per-court tunables: court width, soul-bound height, ramp duration.

## Full paddle-to-paddle court span in pixels; the world speed max derives from it.
@export var court_width: float = 600.0
## Seconds a fair crossing must outlast so the receiver can move and react; sets the world speed max against the crossing.
@export var fair_crossing_seconds: float = 0.833333
## Speed-relock ramp duration in seconds; 0.0 snaps the speed to the tracked entry value instantly.
@export var relock_ramp_seconds: float = 0.12


## Top speed any ball may reach, derived from the court crossing: court_width / fair_crossing_seconds.
func world_max_speed() -> float:
	return court_width / fair_crossing_seconds
