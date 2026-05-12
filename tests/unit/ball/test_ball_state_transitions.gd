## State-transition surface: enter_stored / enter_play / enter_out_rest / enter_out_held property bundles.
extends GutTest

const REST_DAMPING := 1.5

var _ball: Ball
var _config: CourtConfig
var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new()
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([preload("res://resources/items/training_ball.tres")])
	add_child_autofree(_manager)

	_config = load("res://scripts/core/court_config.gd").new()
	_config.rest_roll_damping = REST_DAMPING

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	_ball.court_config = _config
	add_child_autofree(_ball)


# --- enter_stored ---
func test_enter_stored_sets_property_bundle() -> void:
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
func test_enter_play_normal_sets_property_bundle() -> void:
	_ball.global_position = Vector2(0.0, 0.0)
	_ball.enter_play()
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_NORMAL)
	assert_false(_ball.freeze)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)
	assert_almost_eq(_ball.linear_damp, 0.0, 0.001)
	assert_eq(_ball.physics_material_override, Ball.PLAY_MATERIAL)
	assert_eq(_ball.collision_layer, 1)
	assert_eq(_ball.collision_mask, 1)


func test_enter_play_arc_when_above_bound() -> void:
	_ball.global_position = Vector2(0.0, _config.friendship_bound_y - 100.0)
	_ball.enter_play()
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_ARC)
	assert_almost_eq(_ball.gravity_scale, 1.0, 0.001)


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
	assert_eq(_ball.physics_material_override, Ball.PLAY_MATERIAL)


# --- enter_out_rest ---
func test_enter_out_rest_sets_property_bundle() -> void:
	_ball.enter_out_rest()
	assert_eq(_ball.play_state, Ball.PlayState.OUT_REST)
	assert_false(_ball.freeze)
	assert_almost_eq(_ball.gravity_scale, 1.0, 0.001)
	assert_almost_eq(_ball.linear_damp, REST_DAMPING, 0.001)
	assert_eq(_ball.physics_material_override, Ball.REST_MATERIAL)
	assert_eq(_ball.collision_layer, 1)
	assert_eq(_ball.collision_mask, 1)


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
	assert_eq(_ball.physics_material_override, Ball.REST_MATERIAL)


# --- enter_out_held ---
func test_enter_out_held_sets_property_bundle() -> void:
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
	assert_eq(_ball.collision_layer, 1)
	assert_eq(_ball.collision_mask, 1)
	assert_false(_ball.freeze)


# --- miss-detection re-engages on non-HELD ---
func test_miss_detection_re_engages_on_play() -> void:
	_ball.enter_out_held()
	_ball.global_position = Vector2.ZERO
	_ball.enter_play()
	watch_signals(_ball)
	_ball._on_miss_zone_body_entered(_ball)
	assert_signal_emit_count(_ball, "missed", 1)
