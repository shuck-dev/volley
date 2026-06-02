extends GutTest

# Court Lines' raise_floor_speed lifts the floor of tiers above Tier 0 via a tier_floor_lift
# modifier the ball reads; Tier 0 is untouched and the lift never overshoots the ceiling.

const LIFT_FRACTION := 0.02
const COURT_LINES := preload("res://resources/items/court_lines.tres")
const RaiseFloorSpeedScript: GDScript = preload(
	"res://scripts/items/effect/outcomes/raise_floor_speed_outcome.gd"
)

var _manager: Node
var _ball: Ball


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([COURT_LINES])
	add_child_autofree(_manager)

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	add_child_autofree(_ball)


func _buy_court_lines() -> void:
	_manager.economy.friendship_point_balance = 100000
	_manager.purchase("court_lines")
	_manager.activate("court_lines")


func test_outcome_registers_tier_floor_lift_modifier() -> void:
	var outcome: Outcome = COURT_LINES.effects[0].outcomes[0]
	assert_true(
		outcome.get_script() == RaiseFloorSpeedScript, "court_lines drives raise_floor_speed"
	)


func test_tier_zero_floor_unchanged_after_purchase() -> void:
	_ball.current_tier = 0
	var before: float = _ball.tier_floor
	_buy_court_lines()
	assert_almost_eq(_ball.tier_floor, before, 0.01, "Tier 0 floor is never lifted")


func test_above_zero_floor_lifts_by_fraction() -> void:
	_ball.current_tier = 1
	var before: float = _ball.tier_floor
	_buy_court_lines()
	var expected: float = before + LIFT_FRACTION * _ball.ball_world_max_speed
	assert_almost_eq(_ball.tier_floor, expected, 0.01, "Tier 1 floor lifts by the fraction")


func test_lift_scales_with_level() -> void:
	_ball.current_tier = 1
	var before: float = _ball.tier_floor
	_buy_court_lines()
	_manager.purchase("court_lines")
	_manager.activate("court_lines")
	var expected: float = before + 2.0 * LIFT_FRACTION * _ball.ball_world_max_speed
	assert_almost_eq(_ball.tier_floor, expected, 0.01, "lift stacks across levels")


func test_floor_never_exceeds_ceiling() -> void:
	_ball.current_tier = 1
	_manager._effect_manager._effect_state.add_modifier(_huge_lift())
	assert_almost_eq(_ball.tier_floor, _ball.tier_ceiling, 0.01, "lift clamps to the ceiling")


func _huge_lift() -> StatModifier:
	var modifier := StatModifier.new()
	modifier.source_key = "test"
	modifier.stat_key = &"tier_floor_lift"
	modifier.operation = StatModifier.Operation.ADD
	modifier.value = 1.0

	return modifier
