# gdlint:ignore = max-public-methods
extends GutTest

## Drives `_physics_process` with a virtual delta to stay inside the suite budget.

const LANE_X: float = -500.0
const LANE_Y: float = 0.0
const FLOOR_Y: float = 200.0
const AIRBORNE_Y: float = -240.0
const PADDLE_HALF_HEIGHT: float = 27.0

# Large enough that descent (1200 px/s over ~440 px) and the horizontal walk
# (200 px at 400 px/s) each finish in a single step; the controller clamps.
const VIRTUAL_DELTA: float = 0.6
const MAX_STEPS: int = 64

var _paddle: Paddle
var _controller: TimeoutController
var _floor: StaticBody2D


func before_each() -> void:
	_paddle = load("res://scripts/entities/paddle.gd").new()
	var sound := AudioStreamPlayer.new()
	_paddle.add_child(sound)
	_paddle.hit_sound = sound

	var tracker: HitTracker = load("res://scripts/core/hit_tracker.gd").new()
	_paddle.tracker = tracker
	_paddle.add_child(tracker)

	var paddle_collision := CollisionShape2D.new()
	var paddle_shape := RectangleShape2D.new()
	paddle_shape.size = Vector2(20.0, PADDLE_HALF_HEIGHT * 2.0)
	paddle_collision.shape = paddle_shape
	_paddle.add_child(paddle_collision)
	_paddle.collision = paddle_collision

	_paddle.position = Vector2(LANE_X, LANE_Y)
	add_child_autofree(_paddle)

	_floor = StaticBody2D.new()
	_floor.position = Vector2(0.0, FLOOR_Y + 50.0)
	var floor_collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(4000.0, 100.0)
	floor_collision.shape = floor_shape
	_floor.add_child(floor_collision)
	add_child_autofree(_floor)

	var config: TimeoutConfig = TimeoutConfig.new()
	config.walk_duration_seconds = 0.5
	config.equip_pose_offset_x = -200.0
	config.descent_speed = 1200.0
	_controller = load("res://scripts/core/timeout_controller.gd").new()
	_controller.config = config
	_controller.configure(_paddle)
	add_child_autofree(_controller)

	# One real physics frame so the server registers both bodies; without it the
	# first `move_and_slide` call sees no collisions and the paddle never grounds.
	await get_tree().physics_frame


# Drives the controller forward by ticking `_physics_process` with a virtual
# delta until `predicate` is true. Returns false if `MAX_STEPS` is exhausted.
func _drive_until(predicate: Callable, max_steps: int = MAX_STEPS) -> bool:
	for _i in range(max_steps):
		if predicate.call():
			return true
		_controller._physics_process(VIRTUAL_DELTA)
	return predicate.call()


func _at_state(target: TimeoutController.State) -> Callable:
	return func() -> bool: return _controller.get_state() == target


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


func test_cannot_call_timeout_while_descending() -> void:
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	assert_false(
		_controller.can_call_timeout(),
		"timeout cannot be re-called while main character is descending",
	)


# Equip pose arrives after descent + walk-off.
func test_main_character_reaches_equip_pose_after_walk() -> void:
	watch_signals(_controller)
	_controller.call_timeout()
	var reached := _drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	assert_true(reached, "controller should reach AT_EQUIP_POSE within step budget")
	assert_signal_emitted(_controller, "main_character_reached_equip_pose")


func test_equip_pose_is_off_the_lane() -> void:
	_controller.call_timeout()
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
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


func test_end_timeout_restores_main_character_physics() -> void:
	_controller.call_timeout()
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))
	assert_true(
		_paddle.is_physics_processing(),
		"main character should defend again after the timeout ends",
	)


func test_end_timeout_emits_ended_signal_after_walk_on() -> void:
	_controller.call_timeout()
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	watch_signals(_controller)
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))
	assert_signal_emitted(_controller, "timeout_ended")


func test_controller_returns_to_idle_after_full_cycle() -> void:
	_controller.call_timeout()
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))
	assert_false(_controller.is_active())
	assert_true(_controller.can_call_timeout())


# SH-405: physics, not a y target, lands the paddle on the venue floor.
func test_lane_call_timeout_lands_on_floor_collider() -> void:
	_controller.call_timeout()
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	assert_true(_paddle.is_on_floor(), "main character must end up grounded after the walk-off")
	# Resting paddle base is at or above the floor top surface; never below.
	assert_lt(
		_paddle.position.y,
		FLOOR_Y,
		"paddle centre must not pierce below the floor surface",
	)


func test_airborne_call_timeout_eventually_reaches_equip_pose() -> void:
	watch_signals(_controller)
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	var reached := _drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	assert_true(reached, "airborne timeout should eventually reach equip pose")
	assert_signal_emitted(_controller, "main_character_reached_equip_pose")
	assert_ne(_paddle.position.x, LANE_X)
	assert_true(_paddle.is_on_floor())


func test_airborne_call_timeout_defers_equip_pose_signal_until_grounded() -> void:
	watch_signals(_controller)
	_paddle.position = Vector2(LANE_X, AIRBORNE_Y)
	_controller.call_timeout()
	# A descent step alone (no walk-off) must not yet fire the equip-pose signal;
	# use a small delta so the descent doesn't overshoot into WALKING_OFF.
	_controller._physics_process(0.05)
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
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	assert_signal_emit_count(_controller, "timeout_started", 1)
	assert_signal_emit_count(_controller, "main_character_reached_equip_pose", 1)


func test_end_timeout_returns_to_lane_position() -> void:
	_controller.call_timeout()
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))
	assert_almost_eq(_paddle.position.x, LANE_X, 0.5)
	assert_almost_eq(
		_paddle.position.y,
		LANE_Y,
		0.1,
		"walk-on must restore the main character to the playing lane y",
	)


# ASCENDING derives its target from the cached lane-foot minus current half-height, so a
# mid-pose resize is absorbed: whatever the paddle's half-height is at ASCENDING, the foot
# returns to the cached lane-foot. This is the invariant; the test asserts the contract
# rather than driving a manual resize (the autoload's _refresh_from_stats fights manual
# shape mutations mid-drive).
func test_ascending_lands_foot_on_cached_lane_foot() -> void:
	_controller.call_timeout()
	var cached_lane_foot: float = _controller._lane_foot_y
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))

	var rect: RectangleShape2D = _paddle.collision.shape as RectangleShape2D
	var final_foot: float = _paddle.position.y + rect.size.y * 0.5
	assert_almost_eq(
		final_foot,
		cached_lane_foot,
		0.5,
		"ASCENDING must land paddle foot on the cached lane-foot regardless of paddle size",
	)


# SH-405: items resting in the walk path must not body-block the timeout paddle.
func test_timeout_walk_passes_through_resting_items() -> void:
	_paddle.collision_mask = 3
	var item: StaticBody2D = StaticBody2D.new()
	item.collision_layer = 2
	item.collision_mask = 0
	var item_collision := CollisionShape2D.new()
	var item_shape := RectangleShape2D.new()
	item_shape.size = Vector2(60.0, 40.0)
	item_collision.shape = item_shape
	item.add_child(item_collision)
	# Place the item halfway between the lane and the equip pose, sitting on the floor.
	var item_start := Vector2(LANE_X - 100.0, FLOOR_Y - 20.0)
	item.position = item_start
	add_child_autofree(item)
	await get_tree().physics_frame

	_controller.call_timeout()
	var reached := _drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	assert_true(reached, "paddle must reach equip pose past the resting item")
	assert_eq(item.position, item_start, "resting item must not be shoved by the paddle")


func test_drive_blocked_flag_makes_paddle_drive_a_noop() -> void:
	_paddle.drive_blocked = true
	var start_position: Vector2 = _paddle.position
	_paddle.drive(500.0)
	assert_eq(_paddle.velocity, Vector2.ZERO, "drive() must not write velocity while blocked")
	assert_eq(_paddle.position, start_position, "drive() must not move the paddle while blocked")


func test_call_timeout_sets_drive_blocked_and_finish_clears_it() -> void:
	_controller.call_timeout()
	assert_true(_paddle.drive_blocked, "drive must be blocked during the timeout walk")
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))
	assert_false(_paddle.drive_blocked, "finishing the timeout must unblock drive")


func test_finish_at_lane_restores_collision_mask() -> void:
	_paddle.collision_mask = 3
	_controller.call_timeout()
	assert_false(
		_paddle.get_collision_mask_value(2),
		"items layer must be masked off while the timeout is active",
	)
	_drive_until(_at_state(TimeoutController.State.AT_EQUIP_POSE))
	_controller.end_timeout()
	_drive_until(_at_state(TimeoutController.State.IDLE))
	assert_eq(
		_paddle.collision_mask,
		3,
		"finishing at the lane must restore the pre-timeout collision mask",
	)
