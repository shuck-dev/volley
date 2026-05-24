class_name CourtConfig
extends Resource

## Per-court tunables: friendship-bound height, ramp duration, rest-roll damping.

## Speed-relock ramp duration in seconds; 0.0 snaps the speed to the tracked entry value instantly.
@export var relock_ramp_seconds: float = 0.12
## Linear damping applied while the missed ball rolls to rest on the venue floor.
# TODO(SH-394): move into a SurfaceConfig that also owns the floor PhysicsMaterial.
@export var rest_roll_damping: float = 1.5
