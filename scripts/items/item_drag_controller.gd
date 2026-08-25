class_name ItemDragController
extends Node2D

## Owns the held-body during a drag gesture and polls every registered DropTarget for a valid commit.

signal pickup_started(ball_key: String)
signal drop_completed(ball_key: String, release_position: Vector2, over_court: bool)
const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")

const CURSOR_SAMPLE_WINDOW: float = 0.08
const PRESERVED_SPEED_NONE: float = -1.0
const BALL_COLLISION_RADIUS: float = 7.2

## Shared collision footprint for placement queries; a static var stands in because consts cannot hold a Resource.
static var _ball_collision_shape: CircleShape2D

@export var cursor_overlay: BallDropOverlay
## Venue assigns this after _ready (Kit is a Court sibling, not reachable via a scene NodePath).
@export var kit: BallKit

## Test seam: overrides the BallTracker autoload with a standalone instance.
var ball_tracker: Node
var _ball_manager: BallManager
## Held body during a drag gesture (a plain drag-proxy node for kit grabs, Ball for live grabs).
var _held: Node2D = null
var _held_key: String = ""
## A kit origin drops the Kit placement when the release lands elsewhere.
var _held_origin: StringName = &"live"
var _cursor_samples: Array = []
var _mouse_button_down: bool = false
## Rally speed preserved across a grab-and-release.
var _held_preserved_speed: float = PRESERVED_SPEED_NONE
var _cursor_state: int = CursorStateScript.State.DEFAULT


static func _static_init() -> void:
	_ball_collision_shape = CircleShape2D.new()
	_ball_collision_shape.radius = BALL_COLLISION_RADIUS


## Venue calls this after assigning kit, which is wired post-_ready.
func connect_kit() -> void:
	if not kit.slot_pressed.is_connected(_on_kit_slot_pressed):
		kit.slot_pressed.connect(_on_kit_slot_pressed)


func configure(
	ball_manager: Node,
	tracker: Node,
) -> void:
	_ball_manager = ball_manager
	ball_tracker = tracker


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager

	if ball_tracker == null:
		ball_tracker = BallTracker

	# Group lookup so Shop can hand presses to the controller without a NodePath.
	add_to_group(&"drag_controller")

	# Hide the held item's home slot while it is held so the player sees one body, not two.
	if not pickup_started.is_connected(_on_pickup_started):
		pickup_started.connect(_on_pickup_started)
	if not drop_completed.is_connected(_on_drop_completed):
		drop_completed.connect(_on_drop_completed)

	if ball_tracker != null:
		if not ball_tracker.ball_added.is_connected(_on_tracker_ball_added):
			ball_tracker.ball_added.connect(_on_tracker_ball_added)


func _process(_delta: float) -> void:
	var drag_target: Node2D = _drag_target()

	if drag_target == null:
		_set_cursor_state(CursorStateScript.State.DEFAULT, _cursor_position())
		return

	var cursor_target: Vector2 = _cursor_position()
	drag_target.global_position = cursor_target
	_track_cursor_motion(cursor_target)
	_update_cursor_state(cursor_target)

	if not _mouse_button_down:
		if not attempt_release(cursor_target, _screen_position()):
			pass


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return

	_mouse_button_down = mouse_button.pressed
	if mouse_button.pressed or _drag_target() == null:
		return

	# Use the event position so a Camera2D in the venue doesn't break hit-testing.
	attempt_release(_event_world_position(mouse_button), mouse_button.position)


func is_dragging() -> bool:
	return _drag_target() != null


## Returns the active drag-target node for cursor follow
func _drag_target() -> Node2D:
	# Drop a dangling held ball freed out from under the gesture (e.g. a save reload).
	if _held is Ball and not is_instance_valid(_held):
		_held = null
	return _held


func get_held_key() -> String:
	return _held_key


## The temporary drag-proxy node, when the held item isn't a live Ball.
func get_held_body() -> Node2D:
	if _held is Ball:
		return null
	return _held


func get_cursor_state() -> int:
	return _cursor_state


## Grabs a Kit ball as a frozen drag token, since a Kit ball has no live body.
func grab_from_kit(ball_key: String) -> bool:
	if _drag_target() != null:
		return false
	if _ball_manager.get_level(ball_key) <= 0:
		return false

	var definition: BallDefinition = _ball_manager.get_item(ball_key)
	if definition == null or definition.scene == null:
		return false

	var token: Node2D = Node2D.new()
	token.name = "HeldToken_%s" % ball_key
	var ball_instance: Node = definition.scene.instantiate()
	token.add_child(ball_instance)
	(ball_instance as Ball).enter_stored()

	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		current_scene.add_child(token)
	else:
		add_child(token)
	token.global_position = _cursor_position()

	_adopt_held(token, ball_key)

	_held_origin = &"kit"
	_mouse_button_down = true
	pickup_started.emit(ball_key)
	return true


func grab_live_ball(ball_key: String) -> bool:
	if _drag_target() != null:
		return false

	var existing: Ball = null
	if ball_tracker != null:
		existing = ball_tracker.get_ball_for_key(ball_key)

	if existing == null:
		return false

	# Clear the loose-in-venue overlay so an OUT_REST pickup releases like a court grab.
	_ball_manager.clear_loose_in_venue(ball_key)
	existing.enter_out_held()
	_adopt_held(existing, ball_key)
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit(ball_key)
	return true


func _adopt_held(node: Node2D, ball_key: String) -> void:
	var spawn_position: Vector2 = node.global_position
	_held = node
	_held_key = ball_key
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)


## Grabs a ball_tracker-temporary ball (e.g. a Goop split) with no BallManager ownership.
func grab_temporary(ball: Ball) -> bool:
	if _drag_target() != null or ball == null or not is_instance_valid(ball):
		return false

	ball.enter_out_held()
	_adopt_held(ball, "")
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit("")
	return true


## Returns false when no target accepts, so the held body keeps following the cursor.
func attempt_release(release_position: Vector2, screen_position: Vector2 = Vector2.INF) -> bool:
	if _drag_target() == null:
		return false

	var ball_key: String = _held_key
	var has_live_ball: bool = _held is Ball
	var held_ball: Ball = _held as Ball
	var is_temporary: bool = has_live_ball and held_ball.is_temporary

	if _try_accept_into_kit(
		ball_key, release_position, screen_position, has_live_ball, is_temporary
	):
		return true

	var target: DropTarget = find_accepting_target(ball_key, release_position)
	if target == null:
		return false

	# Drop the Kit placement before a non-Kit target takes over.
	if _held_origin == &"kit":
		_ball_manager.remove_from_kit(ball_key)

	if target is CourtDropTarget:
		var velocity: Vector2 = _compute_release_velocity()
		if has_live_ball:
			# The same Ball survives the gesture, transitioning OUT_HELD to PLAY in place.
			_release_live_ball_to_court(release_position, velocity)
		else:
			target.accept(ball_key, release_position, velocity)
			_apply_preserved_speed_after_accept(ball_key)
	elif is_temporary:
		# A temporary ball is freed anywhere but the court.
		_free_temporary_ball(held_ball)
	elif target is VenueDropTarget:
		target.accept(ball_key, release_position, _compute_release_velocity())

	var over_court: bool = target is CourtDropTarget
	_finalise_gesture(ball_key, release_position, over_court)
	return true


# Transitions the held Ball from OUT_HELD → PLAY_NORMAL/PLAY_ARC at the release point with gesture velocity.
func _release_live_ball_to_court(release_position: Vector2, velocity: Vector2) -> void:
	var ball: Ball = _held as Ball
	if ball == null:
		return
	# Capture rally tempo before the transition, since OUT_HELD froze _physics_process.
	var preserved_speed: float = ball.speed
	ball.global_position = release_position
	# Apply velocity after enter_play unfreezes the body, so the next physics tick integrates it.
	ball.enter_play()
	# Re-normalise the gesture velocity onto the preserved rally tempo so the released ball matches.
	if preserved_speed > 0.0 and velocity.length() > 0.0:
		ball.linear_velocity = velocity.normalized() * preserved_speed
	else:
		ball.linear_velocity = velocity
	ball.speed = preserved_speed
	# Re-activate after a live grab cleared loose-in-venue to STORED.
	if not _ball_manager.is_on_court(_held_key):
		_ball_manager.activate(_held_key)


func _apply_preserved_speed_after_accept(ball_key: String) -> void:
	if _held_preserved_speed < 0.0:
		return
	if ball_tracker == null:
		return
	var ball: Ball = ball_tracker.get_ball_for_key(ball_key)
	if ball == null:
		return
	ball.speed = _held_preserved_speed
	if ball.linear_velocity.length() > 0.0:
		ball.linear_velocity = ball.linear_velocity.normalized() * _held_preserved_speed


func find_accepting_target(ball_key: String, world_position: Vector2) -> DropTarget:
	var winner: DropTarget = null
	for node: Node in get_tree().get_nodes_in_group(&"drop_targets"):
		var target: DropTarget = node as DropTarget
		if not target.can_accept(ball_key, world_position, _ball_collision_shape):
			continue
		if winner == null or target.priority < winner.priority:
			winner = target
	return winner


func _free_temporary_ball(held_ball: Ball) -> void:
	if ball_tracker != null:
		ball_tracker.free_temporary(held_ball)


## Frees the tracked ball before it becomes a static Kit icon, so it doesn't linger on the floor.
func _park_held_ball_in_kit() -> void:
	if not (_held is Ball):
		return
	_ball_manager.clear_loose_in_venue(_held_key)
	if ball_tracker != null:
		ball_tracker.release_ball(_held_key)


## Checked before the world-space drop_targets group so a Kit hit takes priority.
func _try_accept_into_kit(
	ball_key: String,
	release_position: Vector2,
	screen_position: Vector2,
	has_live_ball: bool,
	is_temporary: bool,
) -> bool:
	if is_temporary or ball_key.is_empty():
		return false

	var resolved_screen_position: Vector2 = (
		screen_position if screen_position != Vector2.INF else _screen_position()
	)
	if not kit.can_accept(ball_key, resolved_screen_position):
		return false

	if has_live_ball:
		_park_held_ball_in_kit()
	if not kit.try_accept(ball_key, resolved_screen_position):
		return false

	_finalise_gesture(ball_key, release_position, false)
	return true


func _finalise_gesture(ball_key: String, release_position: Vector2, over_court: bool) -> void:
	# The Ball survives a live grab (or was freed elsewhere), so do not free here.
	if _held != null and not (_held is Ball):
		_held.queue_free()

	_reset_gesture_state()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(ball_key, release_position, over_court)


func _reset_gesture_state() -> void:
	_held = null
	_held_key = ""
	_held_origin = &"live"
	_held_preserved_speed = PRESERVED_SPEED_NONE
	_cursor_samples.clear()


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
		return _ball_manager.get_default_ball_launch_velocity()

	var first: Dictionary = _cursor_samples[0]
	var last: Dictionary = _cursor_samples[_cursor_samples.size() - 1]
	var time_delta: float = float(last["time"]) - float(first["time"])
	if time_delta <= 0.0:
		return _ball_manager.get_default_ball_launch_velocity()

	var pos_delta: Vector2 = Vector2(last["position"]) - Vector2(first["position"])
	var velocity: Vector2 = pos_delta / time_delta
	if velocity.length() < 1.0:
		return _ball_manager.get_default_ball_launch_velocity()
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
	if _drag_target() == null:
		return CursorStateScript.State.DEFAULT
	if kit.can_accept(_held_key, _screen_position()):
		return CursorStateScript.State.CAN_DROP
	if _position_accepted_by_any_target(_held_key, world_position):
		return CursorStateScript.State.CAN_DROP
	return CursorStateScript.State.FORBIDDEN


func _position_accepted_by_any_target(ball_key: String, world_position: Vector2) -> bool:
	return find_accepting_target(ball_key, world_position) != null


func _set_cursor_state(state: int, world_position: Vector2) -> void:
	_cursor_state = state
	BallDropOverlay.update_state(state, world_position)


func _on_kit_slot_pressed(ball_key: String) -> void:
	grab_from_kit(ball_key)
	kit.refresh.call_deferred()


func _on_tracker_ball_added(ball: Ball) -> void:
	if not ball.grabbed.is_connected(_on_live_ball_grabbed):
		ball.grabbed.connect(_on_live_ball_grabbed.bind(ball.ball_key))


func _on_live_ball_grabbed(ball: Ball, ball_key: String) -> void:
	if ball_key.is_empty():
		grab_temporary(ball)
	else:
		grab_live_ball(ball_key)


func _on_pickup_started(ball_key: String) -> void:
	kit.hide_slot_for(ball_key)


func _on_drop_completed(ball_key: String, _release_position: Vector2, _over_court: bool) -> void:
	# Loose-in-venue items have no home slot to reveal.
	if _ball_manager.is_loose_in_venue(ball_key):
		return
	kit.reveal_slot_for(ball_key)
