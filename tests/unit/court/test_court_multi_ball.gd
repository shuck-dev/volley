extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const CourtScript: GDScript = preload("res://scripts/core/court.gd")
const RecordingPartnerStub: GDScript = preload("res://tests/stubs/recording_partner_paddle_stub.gd")

var _manager: Node
var _host: Node2D
var _reconciler: BallReconciler
var _court: Court
var _paddle: Paddle
var _storage: SaveStorage


func before_each() -> void:
	_storage = double(SaveStorage).new()
	stub(_storage.write).to_return(true)
	stub(_storage.read).to_return("")

	_manager = ItemManagerScript.new()
	_manager._progression = ProgressionData.new(_storage)
	_manager._effect_manager = EffectManager.new()
	var alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var beta: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_beta")
	var typed_items: Array[ItemDefinition] = [alpha, beta]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	add_child_autofree(_host)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
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
	_court._progression = ProgressionData.new(_storage)
	add_child_autofree(_court)


func _spawn_ball(item_key: String) -> Ball:
	_manager.take(item_key)
	_manager.activate(item_key)
	return _reconciler.get_ball_for_key(item_key)


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


func test_ball_added_emissions_attach_balls_to_court() -> void:
	# Two `ball_added` emissions through the reconciler should leave Court tracking both.
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	var balls: Array[Ball] = _court.ball_tracker.get_balls()
	assert_eq(balls.size(), 2, "Court should track both balls after two ball_added emits")
	assert_true(balls.has(first))
	assert_true(balls.has(second))


func test_ball_removed_drops_court_tracking() -> void:
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	assert_eq(_court.ball_tracker.get_balls().size(), 2)
	assert_true(_court.ball_tracker.get_balls().has(second), "precondition: both balls tracked")

	_reconciler.release_ball("ball_alpha")
	var remaining: Array[Ball] = _court.ball_tracker.get_balls()
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
	_court.ball_tracker.register_miss_zone(zone)

	var ball: Ball = _spawn_ball("ball_alpha")
	assert_not_null(ball)
	watch_signals(ball)
	zone.body_entered.emit(ball)

	assert_signal_emitted(ball, "missed", "ball spawned after registration should miss on the zone")


func test_miss_zone_registered_after_attach_applies_retroactively() -> void:
	# Spawn first, register second; the live ball should still pick up the zone.
	var ball: Ball = _spawn_ball("ball_alpha")
	var zone: MissZone = _make_miss_zone()
	_court.ball_tracker.register_miss_zone(zone)
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

	_court.ball_tracker.register_miss_zone_globally()
	watch_signals(ball)
	zone.body_entered.emit(ball)

	assert_signal_emitted(ball, "missed", "group-discovered zone should reach the tracked ball")


func test_unregister_miss_zone_drops_zone_for_future_attaches() -> void:
	# Register two zones; unregister one. A later-spawned ball should miss on the kept zone
	# but not on the dropped zone, proving unregister actually removes from the tracked set.
	var kept_zone: MissZone = _make_miss_zone()
	var dropped_zone: MissZone = _make_miss_zone()
	_court.ball_tracker.register_miss_zone(kept_zone)
	_court.ball_tracker.register_miss_zone(dropped_zone)
	_court.ball_tracker.unregister_miss_zone(dropped_zone)

	var ball: Ball = _spawn_ball("ball_alpha")
	watch_signals(ball)
	dropped_zone.body_entered.emit(ball)
	assert_signal_not_emitted(ball, "missed", "unregistered zone should not reach later balls")

	kept_zone.body_entered.emit(ball)
	assert_signal_emitted(ball, "missed", "kept zone should still reach later balls")


# --- partner-paddle re-targeting ---
func _make_partner_stub() -> Node2D:
	var partner: Node2D = RecordingPartnerStub.new()
	add_child_autofree(partner)
	return partner


func test_set_partner_paddle_targets_already_attached_balls() -> void:
	# With balls already tracked, registering a partner should hand it the current ball
	# and add it to every tracked ball's effect-processor paddle list.
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	var partner: Node2D = _make_partner_stub()

	_court.ball_tracker.set_partner_paddle(partner)

	assert_eq(
		partner.last_ball,
		_court.ball_tracker.get_current_ball(),
		"partner should be told about the current ball on registration"
	)
	assert_true(
		first.effect_processor.paddles.has(partner),
		"partner should be on the first ball's paddle list"
	)
	assert_true(
		second.effect_processor.paddles.has(partner),
		"partner should be on the second ball's paddle list"
	)


func test_clear_partner_paddle_removes_partner_from_every_ball() -> void:
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	var partner: Node2D = _make_partner_stub()
	_court.ball_tracker.set_partner_paddle(partner)
	assert_true(
		first.effect_processor.paddles.has(partner), "precondition: partner attached to first"
	)

	_court.ball_tracker.clear_partner_paddle(partner)

	assert_false(
		first.effect_processor.paddles.has(partner),
		"partner should be removed from the first ball after clear"
	)
	assert_false(
		second.effect_processor.paddles.has(partner),
		"partner should be removed from the second ball after clear"
	)


func test_set_partner_with_no_balls_then_later_attach_inherits() -> void:
	# Setting the partner before any ball exists is silent; later-attached balls still inherit it.
	var partner: Node2D = _make_partner_stub()
	_court.ball_tracker.set_partner_paddle(partner)
	assert_null(partner.last_ball, "no ball yet, partner should not have been handed one")

	var ball: Ball = _spawn_ball("ball_alpha")

	assert_eq(
		partner.last_ball, ball, "new ball should be handed to the previously-set partner on attach"
	)
	assert_true(
		ball.effect_processor.paddles.has(partner),
		"partner should land on the new ball's paddle list"
	)
