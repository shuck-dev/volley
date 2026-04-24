extends GutTest

## Verifies that court.gd forwards the call_timeout input action to the
## TimeoutController and toggles correctly.

var _game: Node2D
var _paddle: Paddle
var _timeout: TimeoutController


func before_each() -> void:
	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound
	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	_paddle.position = Vector2(-500.0, 0.0)

	_timeout = load("res://scripts/core/timeout_controller.gd").new()
	_timeout.configure(_paddle)

	var autoplay_controller_stub: Node = load("res://tests/stubs/autoplay_controller_stub.gd").new()
	add_child_autofree(autoplay_controller_stub)

	_game = load("res://scripts/core/court.gd").new()
	_game.autoplay_controller = autoplay_controller_stub
	_game.timeout_controller = _timeout
	add_child_autofree(_paddle)
	add_child_autofree(_timeout)
	add_child_autofree(_game)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_game._unhandled_input(event)


func test_pressing_call_timeout_starts_a_timeout() -> void:
	watch_signals(_timeout)
	_press(&"call_timeout")
	assert_signal_emitted(_timeout, "timeout_started")


func test_timeout_action_is_noop_without_controller() -> void:
	_game.timeout_controller = null
	watch_signals(_timeout)
	_press(&"call_timeout")
	assert_signal_not_emitted(_timeout, "timeout_started")
	assert_false(_timeout.is_active())
