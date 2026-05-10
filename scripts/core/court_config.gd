class_name CourtConfig
extends Resource

## Per-court tunables: friendship-bound height, apex physics knobs.
## See designs/01-prototype/tech/08-court-control.md.

## World-space Y of the friendship-bound. Above this line (smaller Y) the ball is in PLAY-ARC.
@export var friendship_bound_y: float = -351.6
## Linear damping applied while above the bound (PLAY-ARC).
@export var arc_linear_damp: float = 0.6
## Centripetal acceleration coefficient (units/s^2 per unit/s of speed) bending velocity toward play.
@export var arc_centripetal_coefficient: float = 6.0
## Speed-relock ramp duration in seconds; 0.0 snaps the speed to the tracked entry value instantly.
@export var relock_ramp_seconds: float = 0.12
