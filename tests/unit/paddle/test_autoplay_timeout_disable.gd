extends GutTest

## Timeout_started forces autoplay off and emits the HUD signal; timeout_ended does not restore.

var _controller: AutoplayController
var _paddle: Paddle
var _ball: Ball
var _timeout: TimeoutController


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

	_timeout = load("res://scripts/core/timeout_controller.gd").new()
	add_child_autofree(_timeout)

	var ai_config: PaddleAIConfig = PaddleAIConfig.new()
	ai_config.reaction_delay_frames = 1
	_controller = load("res://scripts/core/autoplay_controller.gd").new()
	_controller.paddle = _paddle
	_controller.ball = _ball
	_controller.config = ai_config
	_controller.timeout_controller = _timeout
	add_child_autofree(_controller)


func test_timeout_started_disables_active_autoplay_and_emits_toggled_false() -> void:
	_controller.toggle()
	assert_true(_controller.is_enabled(), "precondition: autoplay enabled")
	watch_signals(_controller)
	_timeout.timeout_started.emit()
	assert_false(_controller.is_enabled(), "timeout_started must disable autoplay")
	assert_signal_emitted_with_parameters(_controller, "autoplay_toggled", [false])


func test_timeout_started_when_already_off_is_noop() -> void:
	watch_signals(_controller)
	_timeout.timeout_started.emit()
	assert_false(_controller.is_enabled())
	assert_signal_not_emitted(_controller, "autoplay_toggled")


func test_timeout_ended_does_not_restore_autoplay() -> void:
	_controller.toggle()
	_timeout.timeout_started.emit()
	assert_false(_controller.is_enabled(), "precondition: autoplay off after timeout_started")
	_timeout.timeout_ended.emit()
	assert_false(_controller.is_enabled(), "timeout_ended must NOT auto-restore autoplay")
