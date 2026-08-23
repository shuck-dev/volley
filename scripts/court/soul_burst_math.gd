class_name SoulBurstMath
extends RefCounted

## Math for breaking a consolidation payout into motes.

## Most motes a payout is worth spawning; past this the stream stops being countable
## and starts being a node count.
const MOTE_CAP := 250


## Breaks payout into motes, trading up to bigger motes if the cap is exceeded.
static func split(payout: int) -> Array[int]:
	if payout <= 0:
		return []

	var parts: Array[int] = []
	var remaining := payout

	for smaller in _tiers_below_largest(payout):
		var denomination: int = smaller * 10

		while remaining > smaller * (MOTE_CAP - parts.size()):
			parts.append(denomination)
			remaining -= denomination

	for _index in remaining:
		parts.append(1)

	return parts


## Every tier under the biggest this payout needs, largest first, so each pass can
## leave what the tier below it still has room to carry.
static func _tiers_below_largest(payout: int) -> Array[int]:
	var tiers: Array[int] = []
	var tier := 1

	while payout > tier * MOTE_CAP:
		tiers.push_front(tier)
		tier *= 10

	return tiers
