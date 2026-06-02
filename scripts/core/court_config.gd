class_name CourtConfig
extends Resource

## Per-court tunables: court width, soul-bound height, ramp duration, rest-roll damping.

## Half the court's paddle-to-paddle span in pixels; spawns, miss zones, and the world speed max derive from it.
@export var court_half_width: float = 300.0
## Seconds a fair crossing must outlast so the receiver can move and react; sets the world speed max against the crossing.
@export var fair_crossing_seconds: float = 0.833333
## Speed-relock ramp duration in seconds; 0.0 snaps the speed to the tracked entry value instantly.
@export var relock_ramp_seconds: float = 0.12
## Linear damping applied while the missed ball rolls to rest on the venue floor.
# TODO(SH-394): move into a SurfaceConfig that also owns the floor PhysicsMaterial.
@export var rest_roll_damping: float = 1.5


## Top speed any ball may reach, derived from the court crossing: 2 * half_width / fair_crossing_seconds.
func world_max_speed() -> float:
	return (2.0 * court_half_width) / fair_crossing_seconds
