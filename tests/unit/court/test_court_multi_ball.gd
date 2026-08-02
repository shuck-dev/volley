extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const BallManagerScript: GDScript = preload("res://scripts/items/ball_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/ball_test_helpers.gd")
const CourtScript: GDScript = preload("res://scripts/core/court.gd")
var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler
var _court: Court
var _paddle: Paddle


func before_each() -> void:
	_manager = BallManagerScript.new()
	_manager.state = BallState.new()
	_manager.economy = EconomyState.new()
	var alpha: BallDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var beta: BallDefinition = ItemTestHelpersScript.make_ball_item("ball_beta")
	var typed_items: Array[BallDefinition] = [alpha, beta]
	_manager.items.assign(typed_items)
	_manager.economy.soul_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	add_child_autofree(_host)

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
	_court._ball_manager = _manager
	_court._records = RecordsState.new()
	_court._partners = PartnersState.new()
	add_child_autofree(_court)


func _spawn_ball(ball_key: String) -> Ball:
	_manager.take(ball_key)
	_manager.activate(ball_key)
	return _reconciler.get_ball_for_key(ball_key)


func test_each_ball_owns_its_own_speed_state() -> void:
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	assert_not_null(first)
	assert_not_null(second)
	var first_before: float = first.speed
	var second_before: float = second.speed

	first.increase_speed()

	assert_gt(first.speed, first_before, "first ball advances its own speed")
	assert_eq(second.speed, second_before, "second ball's speed is independent of the first")


func test_paddle_collision_advances_only_the_hit_ball_speed() -> void:
	# Drive a real paddle collision against one ball; only that ball's speed should advance.
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	var first_before: float = first.speed
	var second_before: float = second.speed

	first._on_body_entered(_paddle)

	assert_gt(first.speed, first_before, "hit ball advances its own speed via the collision")
	assert_eq(second.speed, second_before, "other tracked balls are unaffected by the hit")


func test_ball_added_emissions_attach_balls_to_court() -> void:
	# Two `ball_added` emissions through the reconciler should leave Court tracking both.
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	var balls: Array[Ball] = _reconciler.get_balls()
	assert_eq(balls.size(), 2, "Court should track both balls after two ball_added emits")
	assert_true(balls.has(first))
	assert_true(balls.has(second))


func test_ball_removed_drops_court_tracking() -> void:
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	assert_eq(_reconciler.get_balls().size(), 2)
	assert_true(_reconciler.get_balls().has(second), "precondition: both balls tracked")

	_reconciler.release_ball("ball_alpha")
	var remaining: Array[Ball] = _reconciler.get_balls()
	assert_false(remaining.has(first), "released ball should be detached from Court")
	assert_eq(remaining.size(), 1)


# --- miss-zone registration ---
func _make_miss_zone() -> MissZone:
	var zone := MissZone.new()
	add_child_autofree(zone)
	return zone


func test_miss_zone_registered_before_attach_routes_future_balls() -> void:
	# Register the zone with the tracker before any ball spawns; later attaches inherit it.
	var zone: MissZone = _make_miss_zone()
	_reconciler.register_miss_zone(zone)

	var ball: Ball = _spawn_ball("ball_alpha")
	assert_not_null(ball)
	watch_signals(ball)
	zone.body_entered.emit(ball)

	assert_signal_emitted(ball, "missed", "ball spawned after registration should miss on the zone")


func test_miss_zone_registered_after_attach_applies_retroactively() -> void:
	# Spawn first, register second; the live ball should still pick up the zone.
	var ball: Ball = _spawn_ball("ball_alpha")
	var zone: MissZone = _make_miss_zone()
	_reconciler.register_miss_zone(zone)
	watch_signals(ball)

	zone.body_entered.emit(ball)

	assert_signal_emitted(
		ball, "missed", "already-tracked ball should be hooked to a late-registered zone"
	)


func test_register_miss_zone_globally_picks_up_group_members() -> void:
	# Anything in the &"miss_zones" group when the global register fires should propagate to balls.
	var zone: MissZone = _make_miss_zone()
	zone.add_to_group(&"miss_zones")
	var ball: Ball = _spawn_ball("ball_alpha")

	_reconciler.register_miss_zone_globally()
	watch_signals(ball)
	zone.body_entered.emit(ball)

	assert_signal_emitted(ball, "missed", "group-discovered zone should reach the tracked ball")


func test_unregister_miss_zone_drops_zone_for_future_attaches() -> void:
	# Register two zones; unregister one. A later-spawned ball should miss on the kept zone
	# but not on the dropped zone, proving unregister actually removes from the tracked set.
	var kept_zone: MissZone = _make_miss_zone()
	var dropped_zone: MissZone = _make_miss_zone()
	_reconciler.register_miss_zone(kept_zone)
	_reconciler.register_miss_zone(dropped_zone)
	_reconciler.unregister_miss_zone(dropped_zone)

	var ball: Ball = _spawn_ball("ball_alpha")
	watch_signals(ball)
	dropped_zone.body_entered.emit(ball)
	assert_signal_not_emitted(ball, "missed", "unregistered zone should not reach later balls")

	kept_zone.body_entered.emit(ball)
	assert_signal_emitted(ball, "missed", "kept zone should still reach later balls")


func test_attach_second_ball_mid_rally_does_not_change_current_ball() -> void:
	# Thread 4: when a ball is already current, attaching a second ball must not overwrite _current_ball.
	var first: Ball = _spawn_ball("ball_alpha")
	var initial_current: Ball = _reconciler.get_current_ball()
	assert_eq(initial_current, first, "precondition: first ball is current")

	var second: Ball = _spawn_ball("ball_beta")
	assert_eq(
		_reconciler.get_current_ball(),
		first,
		"attaching a second ball mid-rally must not overwrite the current ball",
	)
	assert_true(
		_reconciler.get_balls().has(second),
		"second ball is still tracked even though it did not become current",
	)


# Regression: first-reach tier upgrades must fire independently per ball, not once globally.
# Ball A reaching tier 0 first should not consume the first-reach slot for ball B.
func test_first_reach_upgrade_fires_independently_per_ball() -> void:
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")

	var alpha_level_before: int = _manager.get_level("ball_alpha")
	var beta_level_before: int = _manager.get_level("ball_beta")

	assert_eq(alpha_level_before, 1, "precondition: ball_alpha starts at level 1")
	assert_eq(beta_level_before, 1, "precondition: ball_beta starts at level 1")

	first.current_tier = 0
	first.advance_tier()

	await get_tree().process_frame

	assert_eq(
		_manager.get_level("ball_alpha"),
		alpha_level_before + 1,
		"first ball reaching tier 0 for the first time must trigger its upgrade",
	)

	second.current_tier = 0
	second.advance_tier()

	await get_tree().process_frame

	assert_eq(
		_manager.get_level("ball_beta"),
		beta_level_before + 1,
		"second ball reaching tier 0 for the first time must also trigger its own upgrade, independent of ball_alpha",
	)


# Regression: the reward handler banks soul for ANY tracked ball, not only the current one.
# A single-ball binding let a second ball's consolidation go unrewarded.
func test_non_current_ball_consolidation_banks_soul() -> void:
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")

	assert_eq(
		_reconciler.get_current_ball(),
		first,
		"precondition: the second ball is tracked but not current",
	)

	second.current_tier = 1
	second.advance_tier()

	assert_almost_eq(
		second.soul_multiplier,
		2.0,
		0.001,
		"a tier advance on a tracked but non-current ball must still bank soul",
	)


func test_ball_stats_override_default_stats() -> void:
	var ball_stat_defintion: BallDefinition = ItemTestHelpersScript.make_ball_item("ball_stat")
	var ball_default_defintion: BallDefinition = ItemTestHelpersScript.make_ball_item(
		"ball_default"
	)

	var stats: BaseBallStats = BaseBallStats.new()
	stats.ball_speed_max = GameRules.base.ball_speed_max + 200.0
	ball_stat_defintion.stats = stats

	var typed_items: Array[BallDefinition] = [ball_stat_defintion, ball_default_defintion]

	_manager.items.assign(typed_items)

	var ball_stat: Ball = _spawn_ball("ball_stat")
	var ball_defualt: Ball = _spawn_ball("ball_default")

	assert_eq(
		ball_defualt.max_speed,
		GameRules.base.ball_speed_max,
		"a ball with no stats should use the default"
	)

	assert_ne(
		ball_stat.max_speed,
		GameRules.base.ball_speed_max,
		"a ball with defined stats should override the default"
	)


func test_two_instances_of_same_ball_type_generate_distinct_keys() -> void:
	var plain_item: BallDefinition = ItemTestHelpersScript.make_ball_item("ball_cadence")
	var typed_items: Array[BallDefinition] = [plain_item]
	_manager.items.assign(typed_items)

	var first: Ball = _spawn_ball("ball_cadence")
	var second_key: String = _manager.generate_instance_key("ball_cadence")
	_manager.take("ball_cadence")
	_manager.activate(second_key)
	var second: Ball = _reconciler.get_ball_for_key(second_key)

	assert_ne(first.ball_key, second.ball_key, "each spawned instance owns a distinct ball_key")
