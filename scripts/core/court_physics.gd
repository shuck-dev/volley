## Above-bound arc rule; swap per venue to change the arc without touching Ball.
class_name CourtPhysics
extends Resource

## Downward arc bend in px/s^2 (+y down); the apex emerges from it, so a faster entry arcs higher.
@export var arc_bend: float = 600.0
## Apex ceiling in pixels above the bound so a steep, fast entry cannot loft the ball off-screen.
@export var arc_height_max: float = 220.0


## Downward acceleration this arc visit; a no-upward entry still gets the full bend so it heads down.
func arc_acceleration(entry_speed_up: float) -> float:
	if arc_bend <= 0.0 or arc_height_max <= 0.0:
		return 0.0
	if entry_speed_up <= 0.0:
		return arc_bend

	var natural_apex: float = (entry_speed_up * entry_speed_up) / (2.0 * arc_bend)
	var capped_apex: float = minf(natural_apex, arc_height_max)
	return (entry_speed_up * entry_speed_up) / (2.0 * capped_apex)
