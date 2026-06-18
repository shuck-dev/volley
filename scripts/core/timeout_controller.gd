class_name TimeoutController
extends Node

## State machine for timeout-and-equip: walks the main character off court to an equip pose and back.
## Invariant: when `_state != IDLE`, `main_character` is non-null; enforced at `call_timeout`, trusted elsewhere.

signal timeout_started
signal main_character_reached_equip_pose
signal timeout_ended

## Phases of the main character's timeout; IDLE means no timeout is in flight.
## DESCENDING applies downward velocity until `is_on_floor()`; ASCENDING slides
## back up to the lane y; WALKING_OFF / WALKING_ON run horizontal walks.
enum State { IDLE, DESCENDING, WALKING_OFF, AT_EQUIP_POSE, WALKING_ON, ASCENDING }

@export var main_character: Paddle
@export var config: TimeoutConfig

var _state: State = State.IDLE
var _lane_x: float = 0.0
var _lane_y: float = 0.0
# Foot-y at lane, stable across in-pose resizes because Paddle._apply_size anchors the foot.
# Used by ASCENDING so a paddle that grew during the pose still lands feet-on-lane.
var _lane_foot_y: float = 0.0
var _equip_pose_x: float = 0.0
var _walk_speed: float = 0.0
var _walk_target_x: float = 0.0
var _on_walk_finished: Callable
# Snapshot of the paddle's normal-play collision mask; restored when the timeout ends.
var _saved_collision_mask: int = 0


func _ready() -> void:
	if config == null:
		config = TimeoutConfig.new()
	set_physics_process(false)
	if main_character == null:
		return
	_cache_positions()


func configure(paddle: Paddle) -> void:
	assert(paddle != null, "TimeoutController.configure: paddle must not be null")
	assert(
		_state == State.IDLE,
		"TimeoutController.configure: cannot reconfigure during active timeout",
	)
	main_character = paddle
	_cache_positions()


func is_active() -> bool:
	return _state != State.IDLE


func can_call_timeout() -> bool:
	return _state == State.IDLE


func get_state() -> State:
	return _state


## Starts a timeout, walking the main character off to the equip pose. No-op if already active.
func call_timeout() -> void:
	if not can_call_timeout():
		return
	if main_character == null:
		push_warning("TimeoutController.call_timeout: main_character is null")
		return
	main_character.set_physics_process(false)
	main_character.velocity = Vector2.ZERO
	# Re-cache so a stat-driven paddle resize between timeouts is reflected in the lane y the walk ascends back to.
	_cache_positions()
	# Resting items live on layer 2; mask them off so they act as walls for drops, not body-blockers for the walk.
	_saved_collision_mask = main_character.collision_mask
	main_character.set_collision_mask_value(2, false)
	main_character.drive_blocked = true
	main_character.set_body_collision_enabled(true)
	timeout_started.emit()
	_begin_walk_off()


## Ends a timeout and walks the main character back on court. No-op unless at the equip pose.
func end_timeout() -> void:
	if _state != State.AT_EQUIP_POSE:
		return
	assert(
		main_character != null,
		"TimeoutController invariant: active state with null main_character",
	)
	_begin_walk_back()


func _cache_positions() -> void:
	if main_character == null:
		return
	if config == null:
		config = TimeoutConfig.new()
	_lane_x = main_character.position.x
	_lane_y = main_character.position.y
	_lane_foot_y = _lane_y + _half_height()
	_equip_pose_x = _lane_x + config.equip_pose_offset_x


func _half_height() -> float:
	if main_character == null or main_character.collision == null:
		return 0.0
	var shape: Shape2D = main_character.collision.shape
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.y * 0.5
	return 0.0


# Either descend first (airborne) or skip straight to the horizontal walk (already on floor).
func _begin_walk_off() -> void:
	if main_character.is_grounded():
		_start_horizontal_walk(_equip_pose_x, _on_reached_equip_pose, State.WALKING_OFF)
	else:
		_state = State.DESCENDING
		set_physics_process(true)


func _begin_walk_back() -> void:
	_start_horizontal_walk(_lane_x, _on_reached_lane, State.WALKING_ON)


func _start_horizontal_walk(target_x: float, on_finished: Callable, walk_state: State) -> void:
	_state = walk_state
	_walk_target_x = target_x
	_on_walk_finished = on_finished
	var distance: float = absf(target_x - main_character.position.x)
	# Avoid divide-by-zero when already at target; finish on next frame.
	if config.walk_duration_seconds <= 0.0 or distance <= 0.0:
		_walk_speed = 0.0
	else:
		_walk_speed = distance / config.walk_duration_seconds
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if main_character == null:
		set_physics_process(false)
		return
	match _state:
		State.DESCENDING:
			_step_descent(delta)
		State.ASCENDING:
			_step_ascent(delta)
		State.WALKING_OFF, State.WALKING_ON:
			_step_horizontal_walk(delta)
		_:
			set_physics_process(false)


func _step_descent(_delta: float) -> void:
	main_character.velocity = Vector2(0.0, config.descent_speed)
	main_character.move_and_slide()
	if main_character.is_grounded():
		main_character.velocity = Vector2.ZERO
		_start_horizontal_walk(_equip_pose_x, _on_reached_equip_pose, State.WALKING_OFF)


func _step_ascent(delta: float) -> void:
	# Derive the target from the foot so a mid-pose resize is absorbed; the foot stays on the lane.
	var target_y: float = _lane_foot_y - _half_height()
	var current_y: float = main_character.position.y
	var remaining: float = target_y - current_y
	var step: float = config.descent_speed * delta
	if absf(remaining) <= step:
		main_character.position.y = target_y
		main_character.velocity = Vector2.ZERO
		set_physics_process(false)
		_finish_at_lane()
		return
	main_character.velocity = Vector2(0.0, -config.descent_speed)
	main_character.move_and_slide()


func _step_horizontal_walk(delta: float) -> void:
	var current_x: float = main_character.position.x
	var remaining: float = _walk_target_x - current_x
	var step: float = _walk_speed * delta

	if _walk_speed <= 0.0 or absf(remaining) <= step:
		main_character.position.x = _walk_target_x
		main_character.velocity = Vector2.ZERO
		set_physics_process(false)
		var callback: Callable = _on_walk_finished
		_on_walk_finished = Callable()
		if callback.is_valid():
			callback.call()
		return
	var direction: float = signf(remaining)
	main_character.velocity = Vector2(direction * _walk_speed, 0.0)
	main_character.move_and_slide()


func _on_reached_equip_pose() -> void:
	if not is_instance_valid(main_character):
		return
	_state = State.AT_EQUIP_POSE
	main_character_reached_equip_pose.emit()


func _on_reached_lane() -> void:
	if not is_instance_valid(main_character):
		_finish_at_lane()
		return
	_state = State.ASCENDING
	set_physics_process(true)


func _finish_at_lane() -> void:
	_state = State.IDLE
	if is_instance_valid(main_character):
		main_character.velocity = Vector2.ZERO
		main_character.collision_mask = _saved_collision_mask
		main_character.drive_blocked = false
		main_character.set_body_collision_enabled(false)
		main_character.set_physics_process(true)
	timeout_ended.emit()
