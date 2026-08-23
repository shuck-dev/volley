extends GutTest


func test_payout_returns_one_mote_per_soul() -> void:
	assert_eq(SoulBurstMath.split(3), [1, 1, 1])


func test_payout_at_the_cap_still_returns_single_souls() -> void:
	var cap: int = SoulBurstMath.MOTE_CAP

	assert_eq(SoulBurstMath.split(cap).size(), cap)


func test_payout_just_over_the_cap_trades_one_mote_up() -> void:
	assert_eq(SoulBurstMath.split(SoulBurstMath.MOTE_CAP + 1).count(10), 1)


func test_payout_over_the_cap_keeps_most_motes_single() -> void:
	var parts: Array[int] = SoulBurstMath.split(SoulBurstMath.MOTE_CAP * 2)

	assert_gt(parts.count(1), parts.count(10), "the overflow should be the smaller share")


func test_split_never_exceeds_the_cap(
	p = use_parameters([251, 300, 500, 999, 2510, 25100, 250001])
) -> void:
	assert_lte(SoulBurstMath.split(p).size(), SoulBurstMath.MOTE_CAP)


func test_split_only_mixes_neighbouring_denominations(
	p = use_parameters([251, 300, 999, 2510, 5000, 6000, 25100])
) -> void:
	var denominations: Array[int] = []

	for value in SoulBurstMath.split(p):
		if not denominations.has(value):
			denominations.append(value)

	denominations.sort()

	assert_lte(denominations.size(), 2, "a payout should read as one mote size and its overflow")

	if denominations.size() == 2:
		assert_eq(denominations[1], denominations[0] * 10, "the two sizes should be one step apart")


func test_split_sum_always_equals_payout(
	p = use_parameters([1, 99, 100, 101, 234, 999, 2510, 2517, 25100, 250001])
) -> void:
	var parts: Array[int] = SoulBurstMath.split(p)
	var total := 0
	for value in parts:
		total += value
	assert_eq(total, p)


func test_zero_payout_returns_empty() -> void:
	assert_eq(SoulBurstMath.split(0), [])


func test_negative_payout_returns_empty() -> void:
	assert_eq(SoulBurstMath.split(-5), [])
