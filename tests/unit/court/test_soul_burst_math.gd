extends GutTest


func test_payout_below_hundred_returns_all_ones() -> void:
	assert_eq(SoulBurstMath.split(3), [1, 1, 1])


func test_payout_of_exactly_one_hundred_returns_single_hundred_mote() -> void:
	assert_eq(SoulBurstMath.split(100), [100])


func test_payout_mixes_denominations_largest_first() -> void:
	var parts: Array[int] = SoulBurstMath.split(234)
	assert_eq(parts.count(100), 2)
	assert_eq(parts.count(1), 34)
	assert_eq(parts[0], 100, "largest denomination comes first")


func test_split_sum_always_equals_payout(p = use_parameters([1, 99, 100, 101, 234, 999])) -> void:
	var parts: Array[int] = SoulBurstMath.split(p)
	var total := 0
	for value in parts:
		total += value
	assert_eq(total, p)


func test_zero_payout_returns_empty() -> void:
	assert_eq(SoulBurstMath.split(0), [])


func test_negative_payout_returns_empty() -> void:
	assert_eq(SoulBurstMath.split(-5), [])
