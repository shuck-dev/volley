## Above-bound arc rule; swap per venue to change the arc without touching Ball. Model in 01-court-control.md.
class_name CourtPhysics
extends Resource

## Downward arc bend in px/s^2 (+y down); the apex emerges from it, so a faster entry arcs higher.
@export var arc_bend: float = 600.0
## Apex ceiling in pixels above the bound so a steep, fast entry cannot loft the ball off-screen.
@export var arc_height_max: float = 220.0


## Downward acceleration for this arc visit; zero when there is no upward motion to arc.
func arc_acceleration(entry_speed_up: float) -> float:
	if entry_speed_up <= 0.0:
		return 0.0
	if arc_bend <= 0.0 or arc_height_max <= 0.0:
		return 0.0

	var natural_apex: float = (entry_speed_up * entry_speed_up) / (2.0 * arc_bend)
	var apex: float = clampf(natural_apex, 0.0, arc_height_max)
	return (entry_speed_up * entry_speed_up) / (2.0 * apex)
