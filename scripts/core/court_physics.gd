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

	var apex_at_tuned_bend: float = (entry_speed_up * entry_speed_up) / (2.0 * arc_bend)
	if apex_at_tuned_bend <= arc_height_max:
		return arc_bend

	# Stiffen the bend so the peak lands exactly at the ceiling instead of overshooting.
	return (entry_speed_up * entry_speed_up) / (2.0 * arc_height_max)
