extends GutTest

# Tests for AutoplayController: toggle behaviour, signal, ring-buffer delay, and
# speed cap. Input handling (space key) is covered by integration/gameplay tests.

const PHYSICS_DELTA := 0.016  # One frame at 60fps
const FAR_BEYOND_SNAP_THRESHOLD := 9999.0  # Guarantees max speed in speed-cap tests
const BALL_APPROACHING := Vector2(-100.0, 0.0)  # Ball moving toward paddle (negative x)

var _controller: AutoplayController
var _paddle: CharacterBody2D
var _ball: RigidBody2D
var _config: AutoPlayConfig


func before_each() -> void:
	_ball = load("res://tests/stubs/ball_stub.gd").new()
	_ball.position = Vector2.ZERO
	add_child_autofree(_ball)

	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	add_child_autofree(_paddle)

	_config = AutoPlayConfig.new()
	_config.reaction_delay_frames = 12
	_config.autoplay_speed_scale = 0.75
	_config.snap_threshold = 8.0
	_config.center_drift_scale = 0.3
	_config.center_drift_smoothing = 1.0  # No lerp smoothing in tests for predictable results

	_controller = load("res://scripts/core/autoplay_controller.gd").new()
	_controller.paddle = _paddle
	_controller.ball = _ball
	_controller.config = _config
	add_child_autofree(_controller)


# --- toggle ---
func test_toggle_emits_autoplay_toggled_true() -> void:
	watch_signals(_controller)
	_controller.toggle()
	assert_signal_emitted_with_parameters(_controller, "autoplay_toggled", [true])


func test_toggle_emits_autoplay_toggled_false_on_second_call() -> void:
	_controller.toggle()
	watch_signals(_controller)
	_controller.toggle()
	assert_signal_emitted_with_parameters(_controller, "autoplay_toggled", [false])


func test_toggle_disables_paddle_physics_process_when_active() -> void:
	_controller.toggle()
	assert_false(_paddle.is_physics_processing())


func test_toggle_re_enables_paddle_physics_process_when_deactivated() -> void:
	_controller.toggle()
	_controller.toggle()
	assert_true(_paddle.is_physics_processing())


# --- auto-play movement ---
func test_autoplay_moves_paddle_toward_ball_when_ball_is_below() -> void:
	_ball.position = Vector2(0.0, 200.0)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2(0.0, 0.0)
	_controller.toggle()
	for i in range(_config.reaction_delay_frames + 1):
		_controller._physics_process(PHYSICS_DELTA)
	assert_gt(_paddle.velocity.y, 0.0)


func test_autoplay_moves_paddle_toward_ball_when_ball_is_above() -> void:
	_ball.position = Vector2(0.0, -200.0)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2(0.0, 0.0)
	_controller.toggle()
	for i in range(_config.reaction_delay_frames + 1):
		_controller._physics_process(PHYSICS_DELTA)
	assert_lt(_paddle.velocity.y, 0.0)


func test_autoplay_speed_is_capped_at_configured_scale() -> void:
	_ball.position = Vector2(0.0, FAR_BEYOND_SNAP_THRESHOLD)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2(0.0, 0.0)
	_controller.toggle()
	for i in range(_config.reaction_delay_frames + 1):
		_controller._physics_process(PHYSICS_DELTA)
	assert_almost_eq(_paddle.velocity.y, _paddle.get_speed() * _config.autoplay_speed_scale, 0.01)


# --- ring buffer delay ---
func test_autoplay_does_not_react_to_new_ball_position_within_delay_frames() -> void:
	_ball.position = Vector2.ZERO
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2.ZERO
	_controller.toggle()

	for i in range(_config.reaction_delay_frames):
		_controller._physics_process(PHYSICS_DELTA)

	_ball.position = Vector2(0.0, FAR_BEYOND_SNAP_THRESHOLD)
	_paddle.position = Vector2.ZERO
	_controller._physics_process(PHYSICS_DELTA)
	assert_almost_eq(_paddle.velocity.y, 0.0, 0.01)


func test_autoplay_tracks_new_ball_position_after_delay() -> void:
	_ball.position = Vector2.ZERO
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2.ZERO
	_controller.toggle()

	for i in range(_config.reaction_delay_frames):
		_controller._physics_process(PHYSICS_DELTA)

	_ball.position = Vector2(0.0, FAR_BEYOND_SNAP_THRESHOLD)
	for i in range(_config.reaction_delay_frames):
		_controller._physics_process(PHYSICS_DELTA)

	_paddle.position = Vector2.ZERO
	_controller._physics_process(PHYSICS_DELTA)
	assert_gt(_paddle.velocity.y, 0.0)
