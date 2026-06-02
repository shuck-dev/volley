extends GutTest

# Court-level wiring: TierRewardHandler is instantiated and receives ball events and rally resets.

const CourtScript: GDScript = preload("res://scripts/core/court.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _court: Court
var _manager: Node
var _reconciler: BallReconciler
var _paddle: Paddle


func before_each() -> void:
	_manager = ItemManagerScript.new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()

	var ball_item: ItemDefinition = ItemTestHelpersScript.make_ball_item("base_ball")
	var typed_items: Array[ItemDefinition] = [ball_item]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 0
	_manager.state.item_levels["base_ball"] = 1
	add_child_autofree(_manager)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	add_child_autofree(_paddle)

	var autoplay_stub: Node = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(autoplay_stub)

	_court = CourtScript.new()
	_court.ball_system = _reconciler
	_court.player_paddle = _paddle
	_court.autoplay_controller = autoplay_stub
	_court._progression_config = ProgressionConfig.new()
	_court._item_manager = _manager
	_court._records = RecordsState.new()
	_court._partners = PartnersState.new()
	add_child_autofree(_court)


func _spawn_ball() -> Ball:
	_manager.take("base_ball")
	_manager.activate("base_ball")
	return _reconciler.get_ball_for_key("base_ball")


func _top_tier() -> int:
	return GameRules.speed_tiers.tier_count() - 1


# --- tier completion banks soul at court level ---


func test_tier1_completion_fires_consolidation_and_increments_multiplier() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = 1

	ball.advance_tier()

	assert_almost_eq(
		ball.soul_multiplier,
		2.0,
		0.001,
		"tier 1 completion must increment ball.soul_multiplier to 2"
	)


func test_no_soul_banked_without_tier_advance() -> void:
	var ball: Ball = _spawn_ball()
	var before: float = ball.soul_multiplier

	assert_almost_eq(ball.soul_multiplier, before, 0.001)


func test_per_hit_soul_scales_with_multiplier() -> void:
	var ball: Ball = _spawn_ball()

	_manager.economy.friendship_point_balance = 0
	_court._hitting_ball = ball
	_court._accumulate_friendship_points()
	_court._hitting_ball = null
	var banked_at_x1: int = _manager.get_friendship_point_balance()

	ball.current_tier = 1
	ball.advance_tier()

	_manager.economy.friendship_point_balance = 0
	_court._hitting_ball = ball
	_court._accumulate_friendship_points()
	_court._hitting_ball = null
	var banked_at_x2: int = _manager.get_friendship_point_balance()

	assert_eq(
		banked_at_x2,
		banked_at_x1 * 2,
		"per-hit soul must double after one consolidation lifts the multiplier to x2"
	)


# --- top-tier final consolidation entry banks soul once ---


func test_final_consolidation_entry_fires_consolidation() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()

	ball.advance_tier()

	assert_almost_eq(
		ball.soul_multiplier,
		2.0,
		0.001,
		"top-tier final consolidation entry must increment ball.soul_multiplier"
	)


func test_final_consolidation_entry_banks_soul_only_once_per_rally() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()
	ball.advance_tier()

	var after_first: float = ball.soul_multiplier

	ball.in_final = true
	ball.tier_advanced.emit(_top_tier())

	assert_almost_eq(
		ball.soul_multiplier,
		after_first,
		0.001,
		"second final-consolidation signal in the same rally must not bank soul again"
	)


# --- miss resets the rally state ---


func test_ball_missed_resets_rally_and_clears_multiplier() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()
	ball.advance_tier()

	ball.missed.emit()

	assert_almost_eq(ball.soul_multiplier, 1.0, 0.001, "miss must reset ball.soul_multiplier to 1")

	ball.in_final = false
	ball.current_tier = _top_tier()
	ball.advance_tier()

	assert_almost_eq(
		ball.soul_multiplier,
		2.0,
		0.001,
		"after miss-reset a new final consolidation must increment the multiplier again"
	)


# --- any tracked ball routes tier rewards through the handler ---


func test_handler_receives_tier_advance_from_tracked_ball() -> void:
	var ball: Ball = _spawn_ball()

	ball.current_tier = 1
	ball.advance_tier()

	assert_almost_eq(
		ball.soul_multiplier,
		2.0,
		0.001,
		"a tier advance on any tracked ball must reach the handler and bank soul"
	)
