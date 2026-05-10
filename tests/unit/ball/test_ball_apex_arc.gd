## Ball state-machine, entry-value register, parabolic arc invariants, and relock-ramp tests.
extends GutTest

const BOUND_Y := -100.0
const PARABOLIC_ARC_PHYSICS := preload("res://scripts/core/physics/parabolic_arc_physics.gd")
const COURT_PHYSICS := preload("res://scripts/core/physics/court_physics.gd")

var _ball: Ball
var _config: CourtConfig
var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([preload("res://resources/items/training_ball.tres")])
	add_child_autofree(_manager)

	_config = load("res://scripts/core/court_config.gd").new()
	_config.friendship_bound_y = BOUND_Y
	_config.relock_ramp_seconds = 0.1
	_config.physics = PARABOLIC_ARC_PHYSICS.new()

	_ball = load("res://scripts/entities/ball/ball.gd").new()
	_ball._item_manager = _manager
	_ball.court_config = _config
	add_child_autofree(_ball)
	_ball.global_position = Vector2(0.0, 0.0)
	_ball.linear_velocity = Vector2(_manager.get_stat(&"ball_speed_min"), 0.0)


# --- state machine: starts in PLAY_NORMAL with locked physics ---


func test_ball_starts_in_play_normal() -> void:
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_NORMAL)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)
	assert_almost_eq(_ball.linear_damp, 0.0, 0.001)


func test_normal_to_arc_on_upward_cross() -> void:
	watch_signals(_ball)
	_ball.global_position = Vector2(0.0, BOUND_Y - 10.0)
	_ball._physics_process(0.016)
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_ARC)
	assert_almost_eq(_ball.gravity_scale, 1.0, 0.001)
	assert_signal_emitted_with_parameters(_ball, "play_state_changed", [Ball.PlayState.PLAY_ARC])


func test_arc_to_normal_on_downward_cross() -> void:
	_ball.global_position = Vector2(0.0, BOUND_Y - 10.0)
	_ball._physics_process(0.016)
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_ARC, "precondition: ball entered ARC")
	_ball.global_position = Vector2(0.0, BOUND_Y + 10.0)
	_ball._physics_process(0.016)
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_NORMAL)
	assert_almost_eq(_ball.gravity_scale, 0.0, 0.001)
	assert_almost_eq(_ball.linear_damp, 0.0, 0.001)


# --- entry-value register: persistent, set on first cross, updated by speed events in ARC ---


func test_entry_speed_set_on_first_upward_cross() -> void:
	_ball.speed = 600.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -600.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.entry_speed, 600.0, 0.5)


func test_entry_speed_not_reset_on_subsequent_cross() -> void:
	_ball.speed = 600.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -600.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	_ball.global_position = Vector2(0.0, BOUND_Y + 5.0)
	_ball._physics_process(0.016)
	_ball.speed = 800.0
	_ball.linear_velocity = Vector2(0.0, -800.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	assert_almost_eq(
		_ball.entry_speed, 600.0, 0.5, "register persists across crosses; first value remains."
	)


func test_speed_change_in_arc_updates_entry_value() -> void:
	_ball.speed = 500.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -500.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.entry_speed, 500.0, 0.5)
	_ball.increase_speed()
	assert_almost_eq(
		_ball.entry_speed,
		_ball.speed,
		0.5,
		"in-ARC speed-change events update the tracked entry value"
	)


# --- parabolic arc invariants: ball.gd does not bend velocity or hold magnitude in ARC ---


func test_arc_does_not_renormalise_velocity_to_entry_speed() -> void:
	_ball.speed = 500.0
	_ball.effect_processor.sync_base_speed()
	# Enter ARC at speed 500.
	_ball.linear_velocity = Vector2(0.0, -500.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_ARC)
	# Mid-arc the engine would shed vertical speed to gravity. Simulate that drift, then tick.
	# If the dropped centripetal-reprojection were still in place this would snap back to 500.
	_ball.linear_velocity = Vector2(0.0, -200.0)
	_ball._physics_process(0.016)
	assert_almost_eq(
		_ball.linear_velocity.length(),
		200.0,
		0.5,
		"in-ARC velocity is left to engine gravity; ball.gd no longer renormalises"
	)


func test_arc_does_not_bend_purely_vertical_velocity() -> void:
	# Off-centre, purely vertical motion: under the old centripetal rule this gained an x-component.
	_ball.speed = 500.0
	_ball.effect_processor.sync_base_speed()
	_ball.global_position = Vector2(200.0, BOUND_Y - 50.0)
	_ball.linear_velocity = Vector2(0.0, -500.0)
	_ball._physics_process(0.016)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.linear_velocity.x, 0.0, 0.001, "no centripetal bend toward centre")


# --- relock ramp: speed ramps to entry_speed on ARC -> NORMAL cross ---


func test_relock_ramp_lands_at_entry_speed() -> void:
	_ball.speed = 700.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -700.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.entry_speed, 700.0, 0.5)
	_ball.linear_velocity = Vector2(0.0, 200.0)
	_ball.global_position = Vector2(0.0, BOUND_Y + 5.0)
	_ball._physics_process(0.016)
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_NORMAL)
	for _i in 12:
		_ball._physics_process(0.016)
	assert_almost_eq(
		_ball.linear_velocity.length(),
		700.0,
		1.0,
		"post-ramp magnitude matches the tracked entry value"
	)
	assert_almost_eq(_ball.speed, 700.0, 0.5)


func test_relock_ramp_intermediate_magnitude_between_endpoints() -> void:
	_ball.speed = 700.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -700.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	_ball.linear_velocity = Vector2(0.0, 200.0)
	_ball.global_position = Vector2(0.0, BOUND_Y + 5.0)
	_ball._physics_process(0.016)
	_ball._physics_process(0.02)
	var mid: float = _ball.linear_velocity.length()
	assert_gt(mid, 200.0)
	assert_lt(mid, 700.0)


# --- in-ARC speed events: every entry-value mutation is tracked ---


func test_set_speed_for_streak_in_arc_updates_entry_value() -> void:
	_ball.speed = 500.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -500.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	assert_almost_eq(_ball.entry_speed, 500.0, 0.5)
	_ball.set_speed_for_streak(3)
	assert_almost_eq(
		_ball.entry_speed,
		_ball.speed,
		0.5,
		"streak speed-set in ARC updates the tracked entry value"
	)


# --- snap path on ARC -> NORMAL when relock_ramp_seconds == 0.0 ---


func test_relock_ramp_zero_snaps_to_entry_speed() -> void:
	_config.relock_ramp_seconds = 0.0
	_ball.speed = 700.0
	_ball.effect_processor.sync_base_speed()
	_ball.linear_velocity = Vector2(0.0, -700.0)
	_ball.global_position = Vector2(0.0, BOUND_Y - 5.0)
	_ball._physics_process(0.016)
	_ball.linear_velocity = Vector2(0.0, 200.0)
	_ball.global_position = Vector2(0.0, BOUND_Y + 5.0)
	_ball._physics_process(0.016)
	assert_eq(_ball.play_state, Ball.PlayState.PLAY_NORMAL)
	assert_almost_eq(_ball.speed, 700.0, 0.5, "snap path lands speed at entry_speed")
	assert_almost_eq(
		_ball.linear_velocity.length(), 700.0, 1.0, "snap path lands magnitude at entry_speed"
	)


# --- physics seam: base-class and parabolic step are no-ops on velocity ---


func test_court_physics_base_step_is_noop() -> void:
	var base: CourtPhysics = COURT_PHYSICS.new()
	var body := RigidBody2D.new()
	add_child_autofree(body)
	body.linear_velocity = Vector2(123.0, -456.0)
	base.step(body, _config, 0.016)
	assert_eq(body.linear_velocity, Vector2(123.0, -456.0))


func test_parabolic_arc_step_is_noop() -> void:
	var rule: ParabolicArcPhysics = PARABOLIC_ARC_PHYSICS.new()
	var body := RigidBody2D.new()
	add_child_autofree(body)
	body.linear_velocity = Vector2(123.0, -456.0)
	rule.step(body, _config, 0.016)
	assert_eq(body.linear_velocity, Vector2(123.0, -456.0))
