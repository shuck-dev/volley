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

	var ball_item: ItemDefinition = ItemTestHelpersScript.make_ball_item("old_ball")
	var typed_items: Array[ItemDefinition] = [ball_item]
	_manager.items.assign(typed_items)
	_manager.economy.soul_balance = 0
	_manager.state.item_levels["old_ball"] = 1
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
	_manager.take("old_ball")
	_manager.activate("old_ball")
	return _reconciler.get_ball_for_key("old_ball")


func _top_tier() -> int:
	return GameRules.speed_tiers.tier_count() - 1


# --- soul_multiplier rises by 1 on consolidation (tier advance) ---


func test_soul_multiplier_increments_on_tier_advance() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = 1

	ball.advance_tier()

	assert_almost_eq(
		ball.soul_multiplier, 2.0, 0.001, "tier advance must increment ball.soul_multiplier by 1"
	)


# --- per-hit soul uses the ball's own multiplier ---


func test_per_hit_soul_scales_with_multiplier() -> void:
	var ball: Ball = _spawn_ball()

	_manager.economy.soul_balance = 0
	_paddle.paddle_hit.emit(ball)
	var banked_at_x1: int = _manager.get_soul_balance()

	ball.current_tier = 1
	ball.advance_tier()

	_manager.economy.soul_balance = 0
	_paddle.paddle_hit.emit(ball)
	var banked_at_x2: int = _manager.get_soul_balance()

	assert_eq(
		banked_at_x2,
		banked_at_x1 * 2,
		"per-hit soul must double after one consolidation lifts the multiplier to x2"
	)


# --- miss resets that ball's multiplier to 1 ---


func test_miss_resets_soul_multiplier_to_one() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()
	ball.advance_tier()

	ball.missed.emit(ball)

	assert_almost_eq(ball.soul_multiplier, 1.0, 0.001, "miss must reset ball.soul_multiplier to 1")

	ball.current_tier = _top_tier()
	ball.advance_tier()

	assert_almost_eq(
		ball.soul_multiplier,
		2.0,
		0.001,
		"after miss-reset a new final consolidation must increment the multiplier again"
	)
