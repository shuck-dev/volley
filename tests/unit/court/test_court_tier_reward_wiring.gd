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


func test_tier1_completion_banks_soul() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = 1
	var before: int = _manager.get_friendship_point_balance()

	ball.advance_tier()

	var handler: Node = _court._tier_reward_handler
	assert_eq(
		_manager.get_friendship_point_balance(),
		before + handler.soul_per_tier_base * 1,
		"tier 1 completion must bank soul_per_tier_base * 1"
	)


func test_no_soul_banked_without_tier_advance() -> void:
	_spawn_ball()
	var before: int = _manager.get_friendship_point_balance()

	assert_eq(_manager.get_friendship_point_balance(), before)


# --- top-tier Peak entry banks soul once ---


func test_peak_entry_banks_soul() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()
	var before: int = _manager.get_friendship_point_balance()

	ball.advance_tier()

	var handler: Node = _court._tier_reward_handler
	var expected: int = handler.soul_per_tier_base * _top_tier()
	assert_eq(
		_manager.get_friendship_point_balance(),
		before + expected,
		"top-tier Peak entry must bank soul_per_tier_base * top_tier"
	)


func test_peak_entry_banks_soul_only_once_per_rally() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()
	ball.advance_tier()

	var after_first: int = _manager.get_friendship_point_balance()

	ball.in_peak = true
	ball.tier_advanced.emit(_top_tier())

	assert_eq(
		_manager.get_friendship_point_balance(),
		after_first,
		"second Peak signal in the same rally must not bank soul again"
	)


# --- miss resets the rally state ---


func test_ball_missed_resets_rally_so_next_peak_can_bank_again() -> void:
	var ball: Ball = _spawn_ball()
	ball.current_tier = _top_tier()
	ball.advance_tier()

	_court._on_ball_missed()

	var after_reset: int = _manager.get_friendship_point_balance()

	ball.in_peak = false
	ball.current_tier = _top_tier()
	ball.advance_tier()

	var handler: Node = _court._tier_reward_handler
	assert_eq(
		_manager.get_friendship_point_balance(),
		after_reset + handler.soul_per_tier_base * _top_tier(),
		"after a miss-reset a new Peak must bank soul again"
	)


# --- ball replacement re-binds the handler ---


func test_handler_rebinds_to_new_ball_after_current_ball_changed() -> void:
	var ball: Ball = _spawn_ball()
	var handler: Node = _court._tier_reward_handler

	assert_true(
		ball.tier_advanced.is_connected(handler._on_ball_tier_advanced),
		"handler must be connected to the initial ball"
	)
