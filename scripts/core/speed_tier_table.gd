class_name SpeedTierTable
extends Resource

## The ball-speed ladder; entry bounds are fractions of the derived world max and the tier count is data.

@export var tiers: Array[SpeedTier] = []


## Returns the tier at index, clamping to the first or last entry when out of range.
func get_tier(index: int) -> SpeedTier:
	if tiers.is_empty():
		return null

	var clamped := clampi(index, 0, tiers.size() - 1)

	return tiers[clamped]


## Number of tiers in the ladder.
func tier_count() -> int:
	return tiers.size()
