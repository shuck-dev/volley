class_name SoulBurstMath
extends RefCounted

## Math for breaking a consolidation payout into motes.

## About as many motes as a payout is worth spawning; a leftover soul can add one more.
const MOTE_CAP := 250


## Breaks payout into motes of two neighbouring denominations, the bigger carrying only
## what the smaller cannot fit inside the cap, plus one odd mote for any leftover soul.
static func split(payout: int) -> Array[int]:
	if payout <= 0:
		return []

	var small: int = _small_denomination(payout)
	var large: int = small * 10

	var excess: int = payout - small * MOTE_CAP
	var large_count: int = 0

	if excess > 0:
		large_count = ceili(float(excess) / float(large - small))
		large_count = mini(large_count, floori(float(payout) / float(large)))

	var remainder: int = payout - large_count * large
	var whole_smalls: int = floori(float(remainder) / float(small))
	var small_count: int = mini(whole_smalls, MOTE_CAP - large_count)

	var parts: Array[int] = []

	for _index in large_count:
		parts.append(large)

	for _index in small_count:
		parts.append(small)

	var shortfall: int = remainder - small_count * small

	if shortfall > 0:
		parts.append(shortfall)

	return parts


## The finer of the two denominations a payout streams in.
static func _small_denomination(payout: int) -> int:
	var small := 1

	while payout > small * 10 * MOTE_CAP:
		small *= 10

	return small
