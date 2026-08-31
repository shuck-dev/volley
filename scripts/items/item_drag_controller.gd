class_name ItemDragController
extends Node2D

## Carries a HeldBall on the cursor for the length of a gesture, then offers it to the drop targets.

signal pickup_started(ball_key: String)
signal drop_completed(ball_key: String, release_position: Vector2)
const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")

const CURSOR_SAMPLE_WINDOW: float = 0.08

@export var cursor_overlay: BallDropOverlay

var _held: HeldBall = null
var _cursor_samples: Array = []
var _mouse_button_down: bool = false


func _ready() -> void:
	if not BallTracker.ball_added.is_connected(_on_tracker_ball_added):
		BallTracker.ball_added.connect(_on_tracker_ball_added)


func _process(_delta: float) -> void:
	if _held == null:
		_set_cursor_state(CursorStateScript.State.DEFAULT, _cursor_position())
		return

	var cursor_target: Vector2 = _cursor_position()
	_held.follow(cursor_target)
	_track_cursor_motion(cursor_target)
	_update_cursor_state(cursor_target)

	if not _mouse_button_down:
		attempt_release(cursor_target, _screen_position())


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return

	_mouse_button_down = mouse_button.pressed
	if mouse_button.pressed or _held == null:
		return

	# Use the event position so a Camera2D in the venue doesn't break hit-testing.
	attempt_release(_event_world_position(mouse_button), mouse_button.position)


## Grabs an owned ball, freeing any live body so only the key is carried.
func grab(ball_key: String) -> bool:
	if _held != null:
		return false
	if BallManager.get_level(ball_key) <= 0:
		return false

	var definition: BallDefinition = BallManager.get_item(ball_key)
	if definition == null or definition.scene == null:
		return false

	BallTracker.release_ball(ball_key)
	BallManager.clear_loose_in_venue(ball_key)

	_adopt(HeldBall.new(ball_key, _build_proxy(definition, ball_key), false))
	return true


## Grabs a tracker-temporary ball (e.g. a Goop split), which is carried rather than respawned.
func grab_temporary(ball: Ball) -> bool:
	if _held != null or ball == null or not is_instance_valid(ball):
		return false

	ball.enter_out_held()
	_adopt(HeldBall.new(ball.ball_key, ball, true))
	return true


## Returns false when no target accepts, so the held item keeps following the cursor.
func attempt_release(release_position: Vector2, screen_position: Vector2 = Vector2.INF) -> bool:
	if _held == null:
		return false

	var resolved_screen_position: Vector2 = (
		screen_position if screen_position != Vector2.INF else _screen_position()
	)

	var target: Node = find_accepting_target(release_position, resolved_screen_position)
	if target == null:
		return false

	var ball_key: String = _held.key
	if not target.accept(_held, release_position, _compute_release_velocity()):
		return false

	_finalise_gesture(ball_key, release_position)
	return true


func find_accepting_target(world_position: Vector2, screen_position: Vector2 = Vector2.INF) -> Node:
	if _held == null:
		return null

	var resolved_screen_position: Vector2 = (
		screen_position if screen_position != Vector2.INF else _screen_position()
	)
	var winner: Node = null
	for target: Node in get_tree().get_nodes_in_group(&"drop_targets"):
		if not target.can_accept(_held, world_position, resolved_screen_position):
			continue
		if winner == null or target.drop_priority < winner.drop_priority:
			winner = target
	return winner


## A frozen stand-in that follows the cursor while the real ball does not exist.
func _build_proxy(definition: BallDefinition, ball_key: String) -> Node2D:
	var proxy := Node2D.new()
	proxy.name = "HeldToken_%s" % ball_key

	var ball_instance: Node = definition.scene.instantiate()
	proxy.add_child(ball_instance)

	(ball_instance as Ball).enter_stored()

	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		current_scene.add_child(proxy)
	else:
		add_child(proxy)
	proxy.global_position = _cursor_position()
	return proxy


func _adopt(item: HeldBall) -> void:
	_held = item
	_cursor_samples.clear()
	_track_cursor_motion(_cursor_position())
	_mouse_button_down = true
	pickup_started.emit(item.key)


func _finalise_gesture(ball_key: String, release_position: Vector2) -> void:
	_held = null
	_cursor_samples.clear()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(ball_key, release_position)


func _track_cursor_motion(sample_position: Vector2) -> void:
	var now_ms: float = float(Time.get_ticks_msec()) / 1000.0
	_cursor_samples.append({"time": now_ms, "position": sample_position})

	while _cursor_samples.size() > 1:
		var oldest: Dictionary = _cursor_samples[0]
		if now_ms - float(oldest["time"]) > CURSOR_SAMPLE_WINDOW:
			_cursor_samples.remove_at(0)
		else:
			break


func _compute_release_velocity() -> Vector2:
	if _cursor_samples.size() < 2:
		return BallManager.get_default_ball_launch_velocity()

	var first: Dictionary = _cursor_samples[0]
	var last: Dictionary = _cursor_samples[_cursor_samples.size() - 1]
	var time_delta: float = float(last["time"]) - float(first["time"])
	if time_delta <= 0.0:
		return BallManager.get_default_ball_launch_velocity()

	var pos_delta: Vector2 = Vector2(last["position"]) - Vector2(first["position"])
	var velocity: Vector2 = pos_delta / time_delta
	if velocity.length() < 1.0:
		return BallManager.get_default_ball_launch_velocity()
	return velocity


func _cursor_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return global_position
	return get_global_mouse_position()


func _event_world_position(event: InputEventMouseButton) -> Vector2:
	var canvas_transform: Transform2D = get_canvas_transform()
	return canvas_transform.affine_inverse() * event.position


## Raw viewport position; the Kit lives in a CanvasLayer and hit-tests in screen space.
func _screen_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return Vector2.ZERO
	return viewport.get_mouse_position()


func _update_cursor_state(world_position: Vector2) -> void:
	var state: int = _derive_cursor_state(world_position)
	_set_cursor_state(state, world_position)


func _derive_cursor_state(world_position: Vector2) -> int:
	if _held == null:
		return CursorStateScript.State.DEFAULT
	if find_accepting_target(world_position) != null:
		return CursorStateScript.State.CAN_DROP
	return CursorStateScript.State.FORBIDDEN


func _set_cursor_state(state: int, world_position: Vector2) -> void:
	BallDropOverlay.update_state(state, world_position)


func _on_tracker_ball_added(ball: Ball) -> void:
	if not ball.grabbed.is_connected(_on_live_ball_grabbed):
		ball.grabbed.connect(_on_live_ball_grabbed.bind(ball.ball_key))


func _on_live_ball_grabbed(ball: Ball, _ball_key: String) -> void:
	if ball.is_temporary:
		grab_temporary(ball)
	else:
		grab(ball.ball_key)
