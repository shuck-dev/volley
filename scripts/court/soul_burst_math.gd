class_name SoulBurstMath
extends RefCounted

## Pure math for breaking a consolidation payout into denomination motes.

## Mote denominations, largest first; greedy breakdown picks as many of the largest as fit.
const DENOMINATIONS: Array[int] = [100, 1]


## Breaks payout into the fewest motes using DENOMINATIONS, largest-first. Each entry is one
## mote's value; the values always sum to payout exactly.
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
