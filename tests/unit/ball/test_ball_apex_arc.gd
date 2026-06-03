## Ball NORMAL <-> ARC transitions across the soul bound.
extends GutTest

const BOUND_Y := -100.0

var _ball: Ball
var _config: CourtConfig
var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([preload("res://resources/items/training_ball.tres")])
	add_child_autofree(_manager)

	_config = load("res://scripts/core/court_config.gd").new()
	_config.relock_ramp_seconds = 0.1

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	_ball.court_config = _config
	_ball.bound_y = BOUND_Y
	add_child_autofree(_ball)
	_ball.global_position = Vector2(0.0, 0.0)
	_ball.linear_velocity = Vector2(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager), 0.0
	)


# --- state machine: NORMAL <-> ARC transitions across the soul bound ---


func test_normal_to_arc_on_upward_cross() -> void:
	watch_signals(_ball)
	_ball.global_position = Vector2(0.0, BOUND_Y - 10.0)
	_ball._physics_process(0.016)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.PLAY_ARC])


func test_arc_to_normal_on_downward_cross() -> void:
	watch_signals(_ball)
	_ball.set_play_state(Ball.PlayState.PLAY_ARC)
	_ball.global_position = Vector2(0.0, BOUND_Y + 10.0)
	_ball._physics_process(0.016)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.PLAY_NORMAL])
