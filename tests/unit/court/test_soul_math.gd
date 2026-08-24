extends GutTest


func test_payout_returns_one_mote_per_soul() -> void:
	assert_eq(SoulMath.split(3), [1, 1, 1])


func test_payout_at_the_cap_still_returns_single_souls() -> void:
	var cap: int = SoulMath.MOTE_CAP

	assert_eq(SoulMath.split(cap).size(), cap)


func test_payout_just_over_the_cap_trades_one_mote_up() -> void:
	assert_eq(SoulMath.split(SoulMath.MOTE_CAP + 1).count(10), 1)


func test_payout_over_the_cap_keeps_most_motes_single() -> void:
	var parts: Array[int] = SoulMath.split(SoulMath.MOTE_CAP * 2)

	assert_gt(parts.count(1), parts.count(10), "the overflow should be the smaller share")


func test_split_stays_within_a_mote_of_the_cap(
	p = use_parameters([251, 300, 500, 999, 2429, 2510, 25100, 250001])
) -> void:
	assert_lte(SoulMath.split(p).size(), SoulMath.MOTE_CAP + 1)


func test_split_only_mixes_neighbouring_denominations(
	p = use_parameters([251, 300, 999, 2510, 5000, 6000, 25100])
) -> void:
	var counts := {}

	for value in SoulMath.split(p):
		counts[value] = counts.get(value, 0) + 1

	# One mote may carry an odd remainder; the rest are the two neighbouring sizes.
	var sizes: Array = counts.keys().filter(func(value: int) -> bool: return counts[value] > 1)

	sizes.sort()

	assert_lte(sizes.size(), 2, "a payout should read as one mote size and its overflow")

	if sizes.size() == 2:
		assert_eq(sizes[1], sizes[0] * 10, "the two sizes should be one step apart")


func test_split_sum_survives_an_uneven_trade_up() -> void:
	var parts: Array[int] = SoulMath.split(2429)
	var total := 0

	for value in parts:
		total += value

	assert_eq(total, 2429, "a payout that trades up unevenly must not gain or lose soul")


func test_split_holds_past_the_largest_listed_denomination(
	p = use_parameters([2510000, 2600000, 30000000])
) -> void:
	var parts: Array[int] = SoulMath.split(p)
	var total := 0

	for value in parts:
		total += value

	assert_eq(total, p, "a payout above the listed denominations must still balance")
	assert_lte(parts.size(), SoulMath.MOTE_CAP + 1, "and must still respect the cap")


func test_split_sum_always_equals_payout(
	p = use_parameters([1, 99, 100, 101, 234, 999, 2429, 2510, 2517, 25100, 250001])
) -> void:
	var parts: Array[int] = SoulMath.split(p)
	var total := 0
	for value in parts:
		total += value
	assert_eq(total, p)


func test_zero_payout_returns_empty() -> void:
	assert_eq(SoulMath.split(0), [])


func test_negative_payout_returns_empty() -> void:
	assert_eq(SoulMath.split(-5), [])
