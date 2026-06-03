class_name CourtPhysics
extends Resource

## Above-bound arc rule. The ball crosses the soul bound moving up, arcs over, and crosses back
## down at the mirrored angle, holding a constant speed the whole way. Swap this resource to give
## a venue a different arc without touching Ball.

## Downward acceleration above the bound, in px/s^2 (+y is down). The court's arc "gravity": the
## apex emerges from how fast the ball entered, so a steeper, faster entry arcs higher.
@export var arc_gravity: float = 600.0
## Ceiling on the apex rise above the bound, in pixels, so a steep, fast entry cannot loft the
## ball off-screen. Past this the bend stiffens to cap the peak.
@export var arc_height_max: float = 220.0


## Downward acceleration to apply this arc visit, given the entry's upward speed (px/s). Returns the
## tuned arc_gravity, stiffened only when the emergent apex would exceed arc_height_max. Zero when
## there is no upward motion to arc.
func arc_acceleration(entry_speed_up: float) -> float:
	if entry_speed_up <= 0.0:
		return 0.0
	if arc_height_max <= 0.0:
		return 0.0

	var apex_at_tuned_gravity: float = (entry_speed_up * entry_speed_up) / (2.0 * arc_gravity)
	if apex_at_tuned_gravity <= arc_height_max:
		return arc_gravity

	# Stiffen the bend so the peak lands exactly at the ceiling instead of overshooting.
	return (entry_speed_up * entry_speed_up) / (2.0 * arc_height_max)
