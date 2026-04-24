class_name TimeoutController
extends Node

## State machine for timeout-and-equip: walks the main character off court to an equip pose and back.
## Invariant: when `_state != IDLE`, `main_character` is non-null; enforced at `call_timeout`, trusted elsewhere.

signal timeout_started
signal main_character_reached_equip_pose
signal timeout_ended

## Phases of the main character's timeout; IDLE means no timeout is in flight.
enum State { IDLE, WALKING_OFF, AT_EQUIP_POSE, WALKING_ON }

@export var main_character: Paddle
@export var config: TimeoutConfig

var _state: State = State.IDLE
var _lane_x: float = 0.0
var _equip_pose_x: float = 0.0
var _walk_tween: Tween


func _ready() -> void:
	if config == null:
		config = TimeoutConfig.new()
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
	_cache_positions()
	_state = State.WALKING_OFF
	main_character.set_physics_process(false)
	main_character.velocity = Vector2.ZERO
	timeout_started.emit()
	_walk_to(_equip_pose_x, _on_reached_equip_pose)


## Ends a timeout and walks the main character back on court. No-op unless at the equip pose.
func end_timeout() -> void:
	if _state != State.AT_EQUIP_POSE:
		return
	assert(
		main_character != null,
		"TimeoutController invariant: active state with null main_character",
	)
	_state = State.WALKING_ON
	_walk_to(_lane_x, _on_reached_lane)


func _cache_positions() -> void:
	if main_character == null:
		return
	if config == null:
		config = TimeoutConfig.new()
	_lane_x = main_character.position.x
	_equip_pose_x = _lane_x + config.equip_pose_offset_x


func _walk_to(target_x: float, on_finished: Callable) -> void:
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()
	_walk_tween = create_tween()
	_walk_tween.tween_property(main_character, "position:x", target_x, config.walk_duration_seconds)
	_walk_tween.finished.connect(on_finished)


func _on_reached_equip_pose() -> void:
	if not is_instance_valid(main_character):
		return
	_state = State.AT_EQUIP_POSE
	main_character_reached_equip_pose.emit()


func _on_reached_lane() -> void:
	_state = State.IDLE
	if is_instance_valid(main_character):
		main_character.set_physics_process(true)
	timeout_ended.emit()
