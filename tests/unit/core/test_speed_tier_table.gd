extends GutTest

const CourtConfigScript: GDScript = preload("res://scripts/core/court_config.gd")
const SpeedTierTableResource: SpeedTierTable = preload("res://resources/speed_tier_table.tres")


func test_world_max_derives_720_at_default_width() -> void:
	var config: CourtConfig = CourtConfigScript.new()

	assert_almost_eq(config.world_max_speed(), 720.0, 0.5)


func test_world_max_scales_with_court_width() -> void:
	var config: CourtConfig = CourtConfigScript.new()
	config.court_half_width = 600.0

	assert_almost_eq(config.world_max_speed(), 1440.0, 1.0)


func test_table_has_three_tiers() -> void:
	assert_eq(SpeedTierTableResource.tier_count(), 3)


func test_get_tier_clamps_below_range() -> void:
	assert_eq(SpeedTierTableResource.get_tier(-5), SpeedTierTableResource.get_tier(0))


func test_get_tier_clamps_above_range() -> void:
	assert_eq(SpeedTierTableResource.get_tier(99), SpeedTierTableResource.get_tier(2))


func test_tier0_floor_resolves_to_base_min() -> void:
	var config: CourtConfig = CourtConfigScript.new()
	var world_max: float = config.world_max_speed()
	var tier0: SpeedTier = SpeedTierTableResource.get_tier(0)

	assert_almost_eq(tier0.floor_fraction * world_max, 225.0, 1.0)


func test_tier0_max_range_carries_base_stats_value() -> void:
	var config: CourtConfig = CourtConfigScript.new()
	var world_max: float = config.world_max_speed()
	var tier0: SpeedTier = SpeedTierTableResource.get_tier(0)

	assert_almost_eq(tier0.max_range_fraction * world_max, 340.0, 1.0)


func test_top_tier_ceiling_stays_under_world_max() -> void:
	var top: SpeedTier = SpeedTierTableResource.get_tier(2)

	assert_lt(top.ceiling_fraction, 1.0)
