extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const BallManagerScript: GDScript = preload("res://scripts/items/ball_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/ball_test_helpers.gd")

var _manager: Node
var _reconciler: BallReconciler
var _paddle: Paddle


func before_each() -> void:
	_manager = BallManagerScript.new()
	_manager.state = BallState.new()
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


func _spawn_ball(ball_key: String) -> Ball:
	_manager.take(ball_key)
	_manager.activate(ball_key)
	return _reconciler.get_ball_for_key(ball_key)


func _make_cadence_ball_item(key: String) -> BallDefinition:
	var item: BallDefinition = ItemTestHelpersScript.make_ball_item(key)
	item.scene = load("res://scenes/balls/cadence_ball.tscn")
	return item


func _cadence_processor(ball: Ball) -> CadenceBallEffectProcessor:
	return ball.effect_processor as CadenceBallEffectProcessor


func test_speed_scale_does_not_compound_across_hits() -> void:
	var cadence_item: BallDefinition = _make_cadence_ball_item("ball_cadence")
	var typed_items: Array[BallDefinition] = [cadence_item]
	_manager.items.assign(typed_items)

	var ball: Ball = _spawn_ball("ball_cadence")
	_cadence_processor(ball)._mode = CadenceBallEffectProcessor.Mode.DOUBLE

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
	var cadence_item: BallDefinition = _make_cadence_ball_item("ball_cadence")
	var typed_items: Array[BallDefinition] = [cadence_item]
	_manager.items.assign(typed_items)

	var ball: Ball = _spawn_ball("ball_cadence")
	_cadence_processor(ball)._mode = CadenceBallEffectProcessor.Mode.DOUBLE

	ball.effect_processor.process_frame(0.016)

	assert_gt(ball.effect_processor.scaled_speed, ball.tier_ceiling)


func test_half_shift_falls_below_tier_floor() -> void:
	var cadence_item: BallDefinition = _make_cadence_ball_item("ball_cadence")
	var typed_items: Array[BallDefinition] = [cadence_item]
	_manager.items.assign(typed_items)

	var ball: Ball = _spawn_ball("ball_cadence")
	_cadence_processor(ball)._mode = CadenceBallEffectProcessor.Mode.HALF

	ball.effect_processor.process_frame(0.016)

	assert_lt(ball.effect_processor.scaled_speed, ball.tier_floor)


func test_mode_shift_fires_particle_cue() -> void:
	var cadence_item: BallDefinition = _make_cadence_ball_item("ball_cadence")
	var typed_items: Array[BallDefinition] = [cadence_item]
	_manager.items.assign(typed_items)

	var ball: CadenceBall = _spawn_ball("ball_cadence") as CadenceBall
	assert_not_null(ball, "reconciler should spawn the CadenceBall subclass for a cadence item")

	var processor: CadenceBallEffectProcessor = _cadence_processor(ball)
	processor._time_in_mode = processor._hold_duration

	processor.process_frame(0.016)

	assert_true(ball.shift_cue.emitting)
