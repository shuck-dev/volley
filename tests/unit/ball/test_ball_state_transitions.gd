## State-transition surface: enter_stored / enter_play / enter_out_rest / enter_out_held property values.
extends GutTest

const BOUND_Y := -351.6
const PLAY_ACTIVE_CONFIG: BallStateConfig = preload("res://resources/ball/states/play_active.tres")
const OUT_REST_CONFIG: BallStateConfig = preload("res://resources/ball/states/out_rest.tres")

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

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	_ball.court_config = _config
	_ball.bound_y = BOUND_Y
	add_child_autofree(_ball)


# --- enter_stored ---
func test_enter_stored_sets_property_values() -> void:
	_ball.enter_stored()
	assert_eq(_ball.play_state, Ball.PlayState.STORED)
	assert_true(_ball.freeze)
	assert_eq(_ball.collision_layer, 0)
	assert_eq(_ball.collision_mask, 0)
	assert_eq(_ball.linear_velocity, Vector2.ZERO)


func test_enter_stored_emits_play_state_changed_once() -> void:
	watch_signals(_ball)
	_ball.enter_stored()
	assert_signal_emit_count(_ball, "play_state_changed", 1)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.STORED])


func test_enter_stored_idempotent() -> void:
	_ball.enter_stored()
	watch_signals(_ball)
	_ball.enter_stored()
	assert_signal_emit_count(_ball, "play_state_changed", 0)
	assert_true(_ball.freeze)
	assert_eq(_ball.collision_layer, 0)


# --- enter_play (NORMAL branch — global_position.y >= bound_y) ---
func test_enter_play_normal_sets_property_values() -> void:
	_ball.global_position = Vector2(0.0, 0.0)
	_ball.enter_play()
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_NORMAL)
	assert_false(_ball.freeze)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)
	assert_almost_eq(_ball.linear_damp, 0.0, 0.001)
	assert_eq(_ball.collision_layer, PLAY_ACTIVE_CONFIG.collision_layer)
	assert_eq(_ball.collision_mask, PLAY_ACTIVE_CONFIG.collision_mask)


func test_enter_play_arc_when_above_bound() -> void:
	_ball.global_position = Vector2(0.0, BOUND_Y - 100.0)
	_ball.enter_play()
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_ARC)


func test_mid_arc_speed_change_recomputes_the_bend() -> void:
	_ball.global_position = Vector2(0.0, BOUND_Y - 100.0)
	_ball.enter_play()
	_ball.linear_velocity = Vector2(0.0, 100.0)
	_ball._enter_arc()
	var bend_descending: float = _ball._arc_acceleration

	_ball.speed = _ball.ball_world_max_speed
	_ball.linear_velocity = Vector2(0.0, -1.0)
	_ball._apply_speed()

	assert_gt(_ball._arc_acceleration, bend_descending)


func test_enter_play_emits_once() -> void:
	_ball.enter_stored()
	watch_signals(_ball)
	_ball.enter_play()
	assert_signal_emit_count(_ball, "play_state_changed", 1)


func test_enter_play_idempotent() -> void:
	_ball.global_position = Vector2.ZERO
	_ball.enter_play()
	watch_signals(_ball)
	_ball.enter_play()
	assert_signal_emit_count(_ball, "play_state_changed", 0)


# --- enter_out_rest ---
func test_enter_out_rest_sets_property_values() -> void:
	_ball.enter_out_rest()
	assert_eq(_ball.play_state, Ball.PlayState.OUT_REST)
	assert_false(_ball.freeze)
	assert_almost_eq(_ball.gravity_scale, 1.0, 0.001)
	assert_almost_eq(_ball.linear_damp, OUT_REST_CONFIG.linear_damp, 0.001)
	assert_eq(_ball.collision_layer, OUT_REST_CONFIG.collision_layer)
	assert_eq(_ball.collision_mask, OUT_REST_CONFIG.collision_mask)


func test_enter_out_rest_emits_once() -> void:
	watch_signals(_ball)
	_ball.enter_out_rest()
	assert_signal_emit_count(_ball, "play_state_changed", 1)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.OUT_REST])


func test_enter_out_rest_idempotent() -> void:
	_ball.enter_out_rest()
	watch_signals(_ball)
	_ball.enter_out_rest()
	assert_signal_emit_count(_ball, "play_state_changed", 0)
	assert_almost_eq(_ball.gravity_scale, 1.0, 0.001)


# --- enter_out_held ---
func test_enter_out_held_sets_property_values() -> void:
	_ball.enter_out_held()
	assert_eq(_ball.play_state, Ball.PlayState.OUT_HELD)
	assert_true(_ball.freeze)
	assert_eq(_ball.collision_layer, 0)
	assert_eq(_ball.collision_mask, 0)
	assert_eq(_ball.linear_velocity, Vector2.ZERO)


func test_enter_out_held_suppresses_miss_detection() -> void:
	_ball.enter_out_held()
	watch_signals(_ball)
	# Direct route mimics a miss-zone fire while held; the suppression flag should swallow it.
	_ball._on_miss_zone_body_entered(_ball)
	assert_signal_emit_count(_ball, "missed", 0)


func test_enter_out_held_emits_once() -> void:
	watch_signals(_ball)
	_ball.enter_out_held()
	assert_signal_emit_count(_ball, "play_state_changed", 1)


func test_enter_out_held_idempotent() -> void:
	_ball.enter_out_held()
	watch_signals(_ball)
	_ball.enter_out_held()
	assert_signal_emit_count(_ball, "play_state_changed", 0)
	assert_true(_ball.freeze)
	assert_eq(_ball.collision_layer, 0)


# --- HELD -> PLAY restores collision layer/mask ---
func test_play_restores_collision_after_held() -> void:
	_ball.enter_out_held()
	_ball.global_position = Vector2.ZERO
	_ball.enter_play()
	assert_eq(_ball.collision_layer, PLAY_ACTIVE_CONFIG.collision_layer)
	assert_eq(_ball.collision_mask, PLAY_ACTIVE_CONFIG.collision_mask)
	assert_false(_ball.freeze)


# --- miss-detection re-engages on non-HELD ---
func test_miss_detection_re_engages_on_play() -> void:
	_ball.enter_out_held()
	_ball.global_position = Vector2.ZERO
	_ball.enter_play()
	watch_signals(_ball)
	_ball._on_miss_zone_body_entered(_ball)
	assert_signal_emit_count(_ball, "missed", 1)
