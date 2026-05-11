class_name CourtConfig
extends Resource

## Per-court tunables: friendship-bound height, ramp duration, rest-roll damping.

## World-space Y of the friendship-bound. Above this line (smaller Y) the ball is in PLAY-ARC.
@export var friendship_bound_y: float = -351.6
## Speed-relock ramp duration in seconds; 0.0 snaps the speed to the tracked entry value instantly.
@export var relock_ramp_seconds: float = 0.12
## Linear damping applied while the missed ball rolls to rest on the venue floor.
@export var rest_roll_damping: float = 1.5
