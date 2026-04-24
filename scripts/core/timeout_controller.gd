class_name TimeoutController
extends Node

## State machine for timeout-and-equip: walks the main character off court to an equip pose and back.

signal timeout_started
signal main_character_reached_equip_pose
signal timeout_ended

enum State { IDLE, WALKING_OFF, AT_EQUIP_POSE, WALKING_ON }

const WALK_DURATION_SECONDS: float = 0.6
## Horizontal offset from lane x to equip pose, away from the court on the player's side.
const EQUIP_POSE_OFFSET_X: float = -320.0

@export var main_character: Paddle

var _state: State = State.IDLE
var _lane_x: float = 0.0
var _equip_pose_x: float = 0.0
var _walk_tween: Tween


func _ready() -> void:
	if main_character == null:
		return
	_cache_positions()


func configure(paddle: Paddle) -> void:
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
	if main_character == null:
		return
	_state = State.WALKING_ON
	_walk_to(_lane_x, _on_reached_lane)


func _cache_positions() -> void:
	if main_character == null:
		return
	if _state == State.IDLE:
		_lane_x = main_character.position.x
		_equip_pose_x = _lane_x + EQUIP_POSE_OFFSET_X


func _walk_to(target_x: float, on_finished: Callable) -> void:
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()
	_walk_tween = create_tween()
	_walk_tween.tween_property(main_character, "position:x", target_x, WALK_DURATION_SECONDS)
	_walk_tween.finished.connect(on_finished)


func _on_reached_equip_pose() -> void:
	_state = State.AT_EQUIP_POSE
	main_character_reached_equip_pose.emit()


func _on_reached_lane() -> void:
	_state = State.IDLE
	if is_instance_valid(main_character):
		main_character.set_physics_process(true)
	timeout_ended.emit()
