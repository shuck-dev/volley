class_name SoulMath
extends RefCounted

## Math for breaking soul into motes.

## The maximum number of motes soul can be split into.
const MOTE_CAP := 250

## What a mote can be worth.
const DENOMINATIONS: Array[int] = [1, 10, 100, 1000]


## Breaks payout into motes of two neighbouring denominations, the bigger carrying only
## Plus one odd mote for any leftover.
static func split(payout: int) -> Array[int]:
	if payout <= 0:
		return []

	var small: int = _small_denomination(payout)
	var large: int = _large_denomination(small)

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


static func _large_denomination(denomination: int) -> int:
	var index: int = DENOMINATIONS.find(denomination)

	if index >= 0 and index + 1 < DENOMINATIONS.size():
		return DENOMINATIONS[index + 1]

	return denomination * 10


static func _small_denomination(payout: int) -> int:
	var small: int = DENOMINATIONS[0]

	for denomination in DENOMINATIONS:
		if payout > denomination * MOTE_CAP:
			small = denomination

	return small
