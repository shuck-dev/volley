extends GutTest

# Tests AutoplayController: toggle, signal, ring-buffer delay.

const PHYSICS_DELTA := 0.016  # One frame at 60fps
const BALL_APPROACHING := Vector2(-100.0, 0.0)  # Ball moving toward paddle (negative x)

var _controller: AutoplayController
var _paddle: Paddle
var _ball: Ball
var _config: PaddleAIConfig
var _timeout: TimeoutController


static func ball_below_paddle() -> float:
	# Quarter-arena below paddle: always in-arena, always saturates speed.
	return GameRules.base.arena_height * 0.25


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

	_config = PaddleAIConfig.new()
	_config.reaction_delay_frames = 12
	_config.speed_scale = 0.75
	_config.noise = 0.0

	_timeout = load("res://scripts/core/timeout_controller.gd").new()
	add_child_autofree(_timeout)

	_controller = load("res://scripts/core/autoplay_controller.gd").new()
	_controller.paddle = _paddle
	_controller.ball = _ball
	_controller.config = _config
	_controller.timeout_controller = _timeout
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


# --- auto-play movement ---
func test_autoplay_moves_paddle_toward_ball_when_ball_is_below() -> void:
	_ball.position = Vector2(100.0, 200.0)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2(0.0, 0.0)
	_controller.toggle()
	for i in range(_config.reaction_delay_frames + 1):
		_controller._physics_process(PHYSICS_DELTA)
	assert_gt(_paddle.velocity.y, 0.0)


func test_autoplay_moves_paddle_toward_ball_when_ball_is_above() -> void:
	_ball.position = Vector2(100.0, -200.0)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2(0.0, 0.0)
	_controller.toggle()
	for i in range(_config.reaction_delay_frames + 1):
		_controller._physics_process(PHYSICS_DELTA)
	assert_lt(_paddle.velocity.y, 0.0)


# --- ring buffer delay ---
func test_autoplay_does_not_react_to_new_ball_position_within_delay_frames() -> void:
	_ball.position = Vector2(100.0, 0.0)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2.ZERO
	_controller.toggle()

	for i in range(_config.reaction_delay_frames):
		_controller._physics_process(PHYSICS_DELTA)

	_ball.position = Vector2(100.0, ball_below_paddle())
	_paddle.position = Vector2.ZERO
	_controller._physics_process(PHYSICS_DELTA)
	assert_almost_eq(_paddle.velocity.y, 0.0, 0.01)


func test_autoplay_tracks_new_ball_position_after_delay() -> void:
	_ball.position = Vector2(100.0, 0.0)
	_ball.linear_velocity = BALL_APPROACHING
	_paddle.position = Vector2.ZERO
	_controller.toggle()

	for i in range(_config.reaction_delay_frames):
		_controller._physics_process(PHYSICS_DELTA)

	_ball.position = Vector2(100.0, ball_below_paddle())
	for i in range(_config.reaction_delay_frames):
		_controller._physics_process(PHYSICS_DELTA)

	_paddle.position = Vector2.ZERO
	_controller._physics_process(PHYSICS_DELTA)
	assert_gt(_paddle.velocity.y, 0.0)


# --- timeout interaction ---
func test_timeout_disables_autoplay_and_emits_signal() -> void:
	_controller.toggle()
	assert_true(_controller.is_enabled(), "precondition: autoplay enabled")
	watch_signals(_controller)
	_timeout.timeout_started.emit()
	assert_false(_controller.is_enabled())
	assert_signal_emitted_with_parameters(_controller, "autoplay_toggled", [false])


func test_timeout_end_does_not_re_enable_autoplay() -> void:
	_controller.toggle()
	_timeout.timeout_started.emit()
	_timeout.timeout_ended.emit()
	assert_false(_controller.is_enabled())
