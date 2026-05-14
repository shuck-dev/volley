## Side-miss transition: PLAY -> OUT_REST keeps velocity, engages gravity and damping.
extends GutTest

const REST_DAMPING := 1.5

var _ball: Ball
var _config: CourtConfig
var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.items_world = ItemWorldState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([preload("res://resources/items/training_ball.tres")])
	add_child_autofree(_manager)

	_config = load("res://scripts/core/court_config.gd").new()
	_config.rest_roll_damping = REST_DAMPING

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	_ball.court_config = _config
	add_child_autofree(_ball)


func test_miss_transitions_to_out_rest() -> void:
	watch_signals(_ball)
	_ball.missed.emit()
	assert_eq(_ball.play_state, Ball.PlayState.OUT_REST)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.OUT_REST])


func test_miss_keeps_velocity_at_moment_of_crossing() -> void:
	var crossing_velocity := Vector2(720.0, -180.0)
	_ball.linear_velocity = crossing_velocity
	_ball.missed.emit()
	assert_eq(_ball.linear_velocity, crossing_velocity)


func test_miss_engages_gravity_and_damping() -> void:
	_ball.gravity_scale = 0.0
	_ball.linear_damp = 0.0
	_ball.missed.emit()
	assert_almost_eq(_ball.gravity_scale, 1.0, 0.001)
	assert_almost_eq(_ball.linear_damp, REST_DAMPING, 0.001)


func test_miss_resets_speed_scalar_for_next_rally() -> void:
	_ball.speed = 800.0
	_ball.missed.emit()
	assert_almost_eq(_ball.speed, _ball.min_speed, 0.01)


func test_rest_state_skips_normal_speed_lock() -> void:
	# In PLAY_NORMAL the physics step re-projects velocity to `speed`. In OUT_REST the lock releases.
	var fast_velocity := Vector2(_ball.min_speed * 2.0, 0.0)
	_ball.linear_velocity = fast_velocity
	_ball.missed.emit()
	var pre_step_speed: float = _ball.linear_velocity.length()
	_ball._physics_process(0.016)
	# Speed-lock is off in OUT_REST so velocity is not snapped back to the smaller `speed` scalar.
	assert_almost_eq(_ball.linear_velocity.length(), pre_step_speed, 1.0)
	assert_gt(_ball.linear_velocity.length(), _ball.speed)
