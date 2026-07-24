extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler
var _paddle: Paddle


func before_each() -> void:
	_manager = ItemManagerScript.new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	_manager.economy.soul_balance = 10000
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


func _spawn_ball(item_key: String) -> Ball:
	_manager.take(item_key)
	_manager.activate(item_key)
	return _reconciler.get_ball_for_key(item_key)


func _make_speed_scale_ball_item(key: String) -> ItemDefinition:
	var outcome := StatShiftOutcome.new()
	outcome.stat_key = &"ball_speed_scale"

	var trigger := Trigger.new()
	trigger.type = &"always"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item: ItemDefinition = ItemTestHelpersScript.make_ball_item(key)
	item.effects = [effect]
	return item


func test_speed_scale_does_not_compound_across_hits() -> void:
	var effect_item: ItemDefinition = _make_speed_scale_ball_item("ball_cadence")
	var typed_items: Array[ItemDefinition] = [effect_item]
	_manager.items.assign(typed_items)

	var ball: Ball = _spawn_ball("ball_cadence")
	for shift in _manager.get_effect_manager().get_shifts(ball.item_key):
		shift._mode = StatShift.Mode.DOUBLE

	ball.effect_processor.process_frame(0.016)
	ball._on_body_entered(_paddle)
	var speed_after_first_hit: float = ball.speed

	_paddle.tracker.reset()
	ball.effect_processor.process_frame(0.016)
	ball._on_body_entered(_paddle)
	var speed_after_second_hit: float = ball.speed

	assert_almost_eq(
		speed_after_second_hit - speed_after_first_hit,
		ball.speed_increment,
		0.01,
	)


func test_double_shift_exceeds_tier_ceiling() -> void:
	var effect_item: ItemDefinition = _make_speed_scale_ball_item("ball_cadence")
	var typed_items: Array[ItemDefinition] = [effect_item]
	_manager.items.assign(typed_items)

	var ball: Ball = _spawn_ball("ball_cadence")
	for shift in _manager.get_effect_manager().get_shifts(ball.item_key):
		shift._mode = StatShift.Mode.DOUBLE

	ball.effect_processor.process_frame(0.016)

	assert_gt(ball.effect_processor.scaled_speed, ball.tier_ceiling)


func test_half_shift_falls_below_tier_floor() -> void:
	var effect_item: ItemDefinition = _make_speed_scale_ball_item("ball_cadence")
	var typed_items: Array[ItemDefinition] = [effect_item]
	_manager.items.assign(typed_items)

	var ball: Ball = _spawn_ball("ball_cadence")
	for shift in _manager.get_effect_manager().get_shifts(ball.item_key):
		shift._mode = StatShift.Mode.HALF

	ball.effect_processor.process_frame(0.016)

	assert_lt(ball.effect_processor.scaled_speed, ball.tier_floor)
