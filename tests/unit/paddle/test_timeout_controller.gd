# gdlint:ignore = max-public-methods
extends GutTest

## Drives the walk tween manually so phase boundaries land deterministically without real-time awaits.

const LANE_X: float = -500.0
const LANE_Y: float = 0.0
const FLOOR_Y: float = 600.0
const AIRBORNE_Y: float = -240.0

var _walk_duration: float
var _floor_y: float
var _paddle: Paddle
var _controller: TimeoutController


func before_each() -> void:
	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound

	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)
	_paddle.position = Vector2(LANE_X, LANE_Y)
	add_child_autofree(_paddle)

	var config: TimeoutConfig = load("res://resources/timeout_config.tres").duplicate()
	config.floor_y = FLOOR_Y
	# Round value keeps custom_step deltas readable; not awaited in real time.
	config.walk_duration_seconds = 1.0
	_walk_duration = config.walk_duration_seconds
	_floor_y = config.floor_y
	_controller = load("res://scripts/core/timeout_controller.gd").new()
	_controller.config = config
	_controller.configure(_paddle)
	add_child_autofree(_controller)


func _advance_walk() -> void:
	# Pause first so engine idle doesn't double-advance the step.
	var tween: Tween = _controller._walk_tween
	if tween != null and tween.is_valid():
		tween.pause()
		tween.custom_step(_walk_duration + 0.001)
	await get_tree().process_frame


# --- initial state ---
func test_starts_idle_and_can_call_timeout() -> void:
	assert_false(_controller.is_active(), "should start idle")
	assert_true(_controller.can_call_timeout(), "should accept a timeout when idle")


# --- call_timeout ---
func test_call_timeout_emits_started_signal() -> void:
	watch_signals(_controller)
	_controller.call_timeout()
	assert_signal_emitted(_controller, "timeout_started")


func test_call_timeout_disables_main_character_physics() -> void:
	_controller.call_timeout()
	assert_false(
		_paddle.is_physics_processing(),
		"main character should stop defending during timeout",
	)


func test_call_timeout_rejected_while_already_active() -> void:
	_controller.call_timeout()
	watch_signals(_controller)
	_controller.call_timeout()
	assert_signal_emit_count(_controller, "timeout_started", 0)


func test_cannot_call_timeout_while_walking_off() -> void:
	_controller.call_timeout()
	assert_false(
		_controller.can_call_timeout(),
		"timeout cannot be re-called while main character is off the court",
	)


# Equip pose arrives after two phases: descent to floor, then walk-off.
func test_main_character_reaches_equip_pose_after_walk() -> void:
	watch_signals(_controller)
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	assert_signal_emitted(_controller, "main_character_reached_equip_pose")


func test_equip_pose_is_off_the_lane() -> void:
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	assert_ne(
		_paddle.position.x,
		LANE_X,
		"main character should not be standing on the lane during the timeout",
	)


# --- end_timeout ---
func test_end_timeout_before_reaching_pose_is_ignored() -> void:
	_controller.call_timeout()
	watch_signals(_controller)
	_controller.end_timeout()
	assert_signal_emit_count(_controller, "timeout_ended", 0)


func test_end_timeout_walks_main_character_back_to_lane() -> void:
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	_controller.end_timeout()
	await _advance_walk()
	assert_almost_eq(_paddle.position.x, LANE_X, 0.1)


func test_end_timeout_restores_main_character_physics() -> void:
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	_controller.end_timeout()
	await _advance_walk()
	assert_true(
		_paddle.is_physics_processing(),
		"main character should defend again after the timeout ends",
	)


func test_end_timeout_emits_ended_signal_after_walk_on() -> void:
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	watch_signals(_controller)
	_controller.end_timeout()
	await _advance_walk()
	assert_signal_emitted(_controller, "timeout_ended")


func test_controller_returns_to_idle_after_full_cycle() -> void:
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	_controller.end_timeout()
	await _advance_walk()
	assert_false(_controller.is_active())
	assert_true(_controller.can_call_timeout())


# SH-217 + SH-243: mid-court paddles descend before walking off.
func test_lane_call_timeout_descends_before_walking_off() -> void:
	_controller.call_timeout()
	await _advance_walk()
	assert_almost_eq(
		_paddle.position.y,
		FLOOR_Y,
		0.1,
		"first phase from the lane should land on the floor",
	)
	var horizontal_drift: float = absf(_paddle.position.x - LANE_X)
	var full_walk_distance: float = absf(_controller.config.equip_pose_offset_x)
	assert_lt(
		horizontal_drift,
		full_walk_distance * 0.25,
		"main character must spend the first phase descending, not walking off",
	)


func test_airborne_call_timeout_does_not_reach_equip_pose_in_one_walk() -> void:
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	await _advance_walk()
	var horizontal_drift: float = absf(_paddle.position.x - LANE_X)
	var full_walk_distance: float = absf(_controller.config.equip_pose_offset_x)
	assert_lt(
		horizontal_drift,
		full_walk_distance * 0.25,
		"airborne main character must spend the first phase descending, not walking off",
	)


func test_airborne_call_timeout_lands_on_floor_before_walking_off() -> void:
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	await _advance_walk()
	assert_almost_eq(
		_paddle.position.y,
		FLOOR_Y,
		0.1,
		"main character should land on the floor after the descent phase",
	)


# SH-243: descent target must be the venue floor, not the cached lane y.
func test_airborne_descent_target_is_floor_not_lane() -> void:
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	await _advance_walk()
	assert_ne(
		_paddle.position.y,
		LANE_Y,
		"descent must not stop at mid-court lane y; floor is the target",
	)
	assert_almost_eq(
		_paddle.position.y,
		FLOOR_Y,
		0.1,
		"descent target is config.floor_y (court bottom)",
	)


# SH-243 fast-path: a paddle already at floor y skips the descent phase.
func test_grounded_at_floor_walks_off_without_descent() -> void:
	_paddle.position = Vector2(LANE_X, FLOOR_Y)
	_controller.call_timeout()
	await _advance_walk()
	assert_almost_eq(_paddle.position.y, FLOOR_Y, 0.1, "no descent phase when already on the floor")
	assert_ne(
		_paddle.position.x,
		LANE_X,
		"grounded paddle should reach the equip pose in one walk duration",
	)


func test_airborne_call_timeout_eventually_reaches_equip_pose() -> void:
	watch_signals(_controller)
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	assert_signal_emitted(_controller, "main_character_reached_equip_pose")
	assert_ne(_paddle.position.x, LANE_X)
	assert_almost_eq(_paddle.position.y, FLOOR_Y, 0.1)


func test_airborne_call_timeout_defers_equip_pose_signal_until_grounded() -> void:
	watch_signals(_controller)
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	await _advance_walk()
	assert_signal_emit_count(
		_controller,
		"main_character_reached_equip_pose",
		0,
		"equip-pose signal must wait for both the descent and the walk-off",
	)


func test_repeated_call_timeout_while_airborne_stays_single_run() -> void:
	watch_signals(_controller)
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	assert_signal_emit_count(_controller, "timeout_started", 1)
	assert_signal_emit_count(_controller, "main_character_reached_equip_pose", 1)


func test_end_timeout_returns_to_lane_position() -> void:
	_controller.call_timeout()
	await _advance_walk()
	await _advance_walk()
	_paddle.position.y = AIRBORNE_Y
	_controller.end_timeout()
	await _advance_walk()
	assert_almost_eq(_paddle.position.x, LANE_X, 0.1)
	assert_almost_eq(
		_paddle.position.y,
		LANE_Y,
		0.1,
		"walk-on must restore the main character to the playing lane y",
	)
