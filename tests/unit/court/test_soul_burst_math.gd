extends GutTest


func test_payout_returns_one_mote_per_soul() -> void:
	assert_eq(SoulBurstMath.split(3), [1, 1, 1])


func test_large_payout_returns_a_mote_for_every_soul() -> void:
	assert_eq(SoulBurstMath.split(234).size(), 234)


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
