## SH-288 multi-ball Court wiring: every tracked ball receives paddle-hit speed advances,
## not just the back-compat `ball` handle. See designs/01-prototype/21-ball-dynamics.md.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const CourtScript: GDScript = preload("res://scripts/core/court.gd")

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


func test_paddle_hit_advances_speed_on_every_tracked_ball() -> void:
	# Wire two balls through the reconciler. Both should react to a single paddle_hit.
	var first: Ball = _spawn_ball("ball_alpha")
	var second: Ball = _spawn_ball("ball_beta")
	assert_not_null(first)
	assert_not_null(second)
	var first_before: float = first.speed
	var second_before: float = second.speed

	_paddle.paddle_hit.emit()

	assert_gt(first.speed, first_before, "first ball should accelerate on paddle hit")
	assert_gt(second.speed, second_before, "second tracked ball should also accelerate")


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
