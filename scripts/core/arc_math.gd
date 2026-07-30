class_name ArcMath
extends RefCounted

## Pure math for the above-bound arc rule: downward bend so a ball crossing the soul bound arcs back down.

## Downward arc bend in px/s^2 (+y down); the apex emerges from it, so a faster entry arcs higher.
const ARC_BEND: float = 600.0


## Downward acceleration this arc visit; a no-upward entry still gets the full bend so it heads down.
static func arc_acceleration(entry_speed_up: float, arc_height_max: float) -> float:
	if arc_height_max <= 0.0:
		return 0.0
	if entry_speed_up <= 0.0:
		return ARC_BEND

	var natural_apex: float = (entry_speed_up * entry_speed_up) / (2.0 * ARC_BEND)
	var capped_apex: float = minf(natural_apex, arc_height_max)
	return (entry_speed_up * entry_speed_up) / (2.0 * capped_apex)
