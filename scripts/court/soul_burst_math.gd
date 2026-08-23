class_name SoulBurstMath
extends RefCounted

## Math for breaking a consolidation payout into motes.

## Mote denominations. One soul each, so a payout reads as a countable stream.
const DENOMINATIONS: Array[int] = [1]


## Breaks payout into the fewest motes, largest-first.
static func split(payout: int) -> Array[int]:
	if payout <= 0:
		return []

	var parts: Array[int] = []
	var remaining := payout

	for denomination in DENOMINATIONS:
		while remaining >= denomination:
			parts.append(denomination)
			remaining -= denomination

	return parts
