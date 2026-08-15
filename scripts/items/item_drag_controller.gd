class_name ItemDragController
extends Node2D

## Owns the held-body during a drag gesture and polls every registered DropTarget for a valid commit.

signal pickup_started(ball_key: String)
signal drop_completed(ball_key: String, release_position: Vector2, over_court: bool)
const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")

const CURSOR_SAMPLE_WINDOW: float = 0.08
const PRESERVED_SPEED_NONE: float = -1.0
## Minimum cursor travel before a rack-origin gesture counts as a real drag.
const COMMIT_MOVEMENT_THRESHOLD_PX: float = 6.0
const BALL_COLLISION_RADIUS: float = 7.2

## Shared physical footprint for placement-clearance queries and held-body colliders; GDScript
## consts can't hold a Resource instance, so a static var built in _static_init stands in for one.
static var _ball_collision_shape: CircleShape2D

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var cursor_overlay: BallDropOverlay
## Venue assigns this after _ready (Kit is a Court sibling, not reachable via a scene NodePath).
@export var kit: BallKit

## Test seam: overrides the BallTracker autoload with a standalone instance.
var ball_tracker: Node
var _ball_manager: BallManager
## Held body during a drag gesture (a plain drag-proxy node for rack grabs, Ball for live grabs).
var _held: Node2D = null
var _held_key: String = ""
var _held_was_on_court: bool = false
## &"rack" or &"live"; rack origins gate the click-without-movement no-op.
var _held_origin: StringName = &"rack"
var _cursor_samples: Array = []
var _press_position: Vector2 = Vector2.ZERO
var _gesture_below_threshold: bool = true
var _mouse_button_down: bool = false
## Negative means no preserved energy; positive carries rally speed across grab+release.
var _held_preserved_speed: float = PRESERVED_SPEED_NONE
var _cursor_state: int = CursorStateScript.State.DEFAULT
var _release_pending: bool = false


static func _static_init() -> void:
	_ball_collision_shape = CircleShape2D.new()
	_ball_collision_shape.radius = BALL_COLLISION_RADIUS


## Venue calls this after assigning kit (Kit is wired post-_ready; see the kit doc comment above).
func connect_kit() -> void:
	if not kit.slot_pressed.is_connected(_on_kit_slot_pressed):
		kit.slot_pressed.connect(_on_kit_slot_pressed)


func configure(
	ball_manager: Node,
	rack_display: RackDisplay,
	drop_area: Area2D,
	tracker: Node,
) -> void:
	_ball_manager = ball_manager
	rack = rack_display
	rack_drop_target = drop_area
	ball_tracker = tracker


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager

	if ball_tracker == null:
		ball_tracker = BallTracker

	# Group lookup so Shop can hand presses to the controller without a NodePath.
	add_to_group(&"drag_controller")

	if rack != null and not rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		rack.slot_pressed.connect(_on_rack_slot_pressed)

	# Hide rack slots while their item is held so the player sees one body, not two.
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

	if _gesture_below_threshold:
		if cursor_target.distance_to(_press_position) >= COMMIT_MOVEMENT_THRESHOLD_PX:
			_gesture_below_threshold = false
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

	# Use event position so a Camera2D in the venue doesn't break rack hit-testing.
	if not attempt_release(_event_world_position(mouse_button), mouse_button.position):
		# Gesture stays alive: keep following the cursor and retry release each frame.
		_release_pending = true


func is_dragging() -> bool:
	return _drag_target() != null


## Returns the active drag-target node for cursor follow
func _drag_target() -> Node2D:
	# The held ball can be freed out from under the gesture (e.g. a save reload); drop the dangling ref.
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


## Activation defers to release-over-court so a click-without-movement is a no-op.
func grab_from_rack(ball_key: String) -> bool:
	if _drag_target() != null:
		return false
	if _ball_manager.get_level(ball_key) <= 0:
		return false
	if _ball_manager.is_on_court(ball_key):
		return false

	var stored: Ball = null
	if ball_tracker != null:
		stored = ball_tracker.create_ball_from_key(ball_key)

	if stored == null:
		return false

	# The STORED Ball IS the drag target; it stays tracked, now OUT_HELD until release.
	stored.enter_out_held()
	_adopt_held(stored, ball_key)

	# Free the slot while held so a concurrent insert fills from slot 0; restore re-assigns it.
	_ball_manager.release_rack_slot(ball_key)

	_held_was_on_court = false
	_held_origin = &"rack"
	# A grab only happens on a press; assume mouse is down so polling waits for mouse-up.
	_mouse_button_down = true
	pickup_started.emit(ball_key)
	return true


## A Kit ball has no live body (Kit renders a static icon); grabbing spawns a frozen drag token,
## the same shape ShopItem uses for an unpurchased ball.
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

	_held_was_on_court = false
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

	# Capture on-court state before clearing the overlay; OUT_REST cancels must skip deactivate.
	var was_on_court: bool = _ball_manager.is_on_court(ball_key)
	# OUT_REST pickup also routes through here; clear the loose-in-venue overlay so a release-over-rack
	# (or any non-venue target) restores the slot exactly like a live-grab originating from the court.
	_ball_manager.clear_loose_in_venue(ball_key)
	existing.enter_out_held()
	_adopt_held(existing, ball_key)
	_held_was_on_court = was_on_court
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit(ball_key)
	return true


func _adopt_held(node: Node2D, ball_key: String) -> void:
	var spawn_position: Vector2 = node.global_position
	_held = node
	_held_key = ball_key
	_press_position = spawn_position
	_gesture_below_threshold = true
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)


## Grabs a ball_tracker-temporary ball (e.g. a Goop split child); no BallManager ownership involved.
func grab_temporary(ball: Ball) -> bool:
	if _drag_target() != null or ball == null or not is_instance_valid(ball):
		return false

	ball.enter_out_held()
	_adopt_held(ball, "")
	_held_was_on_court = false
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit("")
	return true


## Adopts a freshly-purchased instance into the rack; ShopItem calls this after Shop.take().
func adopt_purchased_into_rack(instance_key: String) -> void:
	if ball_tracker == null:
		return
	ball_tracker.create_ball_from_key(instance_key)


## Returns false on no valid target so the held body stays with the cursor.
## `screen_position` defaults to a live viewport lookup; direct/test callers may pin it.
func attempt_release(release_position: Vector2, screen_position: Vector2 = Vector2.INF) -> bool:
	if _drag_target() == null:
		return false

	var ball_key: String = _held_key
	var has_live_ball: bool = _held is Ball
	var held_ball: Ball = _held as Ball
	var is_temporary: bool = has_live_ball and held_ball.is_temporary

	# Direct callers bypass _process; re-check distance to keep the no-op gate honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			release_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)

	# Rack-origin press-and-release without movement cancels back to source instead of activating.
	if below_threshold and _held_origin == &"rack" and not _held_was_on_court:
		_cancel_rack_gesture(ball_key, release_position, has_live_ball, is_temporary)
		return true

	if _try_accept_into_kit(
		ball_key, release_position, screen_position, has_live_ball, is_temporary
	):
		return true

	var target: DropTarget = find_accepting_target(ball_key, release_position)
	if target == null:
		return false

	# Landing anywhere else drops the Kit placement; the target below handles the rest, same as rack-origin.
	if _held_origin == &"kit":
		_ball_manager.remove_from_kit(ball_key)

	if target is CourtDropTarget:
		var velocity: Vector2 = _compute_release_velocity()
		if has_live_ball:
			# Same Ball survives the gesture; transition OUT_HELD → PLAY in place at the release point.
			_release_live_ball_to_court(release_position, velocity)
		else:
			target.accept(ball_key, release_position, velocity)
			_apply_preserved_speed_after_accept(ball_key)
	elif is_temporary:
		# A temporary ball never joins the rack/venue registry; anywhere but the court just frees it.
		_free_temporary_ball(held_ball)
	elif target is VenueDropTarget:
		target.accept(ball_key, release_position, _compute_release_velocity())
	else:
		# Restore is the safety net when BallManager was already STORED so accept's deactivate was a no-op.
		target.accept(ball_key, release_position, Vector2.ZERO)
		if has_live_ball:
			_restore_held_ball_to_stored(ball_key)

	var over_court: bool = target is CourtDropTarget
	_finalise_gesture(ball_key, release_position, over_court)
	rack.refresh()
	return true


# Transitions the held Ball from OUT_HELD → PLAY_NORMAL/PLAY_ARC at the release point with gesture velocity.
func _release_live_ball_to_court(release_position: Vector2, velocity: Vector2) -> void:
	var ball: Ball = _held as Ball
	if ball == null:
		return
	# Capture rally tempo before any state transition; the OUT_HELD freeze suppressed _physics_process,
	# so ball.speed still holds the value the player was rallying at.
	var preserved_speed: float = ball.speed
	ball.global_position = release_position
	# enter_play unfreezes the body and picks NORMAL/ARC based on Y; apply velocity after so the
	# write lands on an unfrozen body and the next physics tick integrates from the gesture.
	ball.enter_play()
	# Re-normalise the gesture velocity onto the preserved rally tempo so the released ball matches.
	if preserved_speed > 0.0 and velocity.length() > 0.0:
		ball.linear_velocity = velocity.normalized() * preserved_speed
	else:
		ball.linear_velocity = velocity
	ball.speed = preserved_speed
	# Keep BallManager in sync: a rack-origin gesture leaves placement=STORED until activate runs.
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


## Returns a held Ball to its rack slot in STORED state; safety net when rack accept's deactivate is a no-op.
func _restore_held_ball_to_stored(ball_key: String) -> void:
	if not (_held is Ball):
		return
	# Live OUT_REST → rack-drop carries a loose-in-venue overlay that would otherwise hide the restored slot.
	_ball_manager.clear_loose_in_venue(ball_key)
	# Rack pickups freed the slot on grab; re-claim one before reading the slot position.
	_ball_manager.reassign_rack_slot(ball_key)
	(_held as Ball).enter_stored()
	if rack != null:
		(_held as Ball).global_position = rack.get_slot_position_for(ball_key)


func _free_temporary_ball(held_ball: Ball) -> void:
	if ball_tracker != null:
		ball_tracker.free_temporary(held_ball)


## Cancels a rack-origin gesture back to its source; a click-without-movement is a no-op, not a drop.
func _cancel_rack_gesture(
	ball_key: String, release_position: Vector2, has_live_ball: bool, is_temporary: bool
) -> void:
	if has_live_ball and not is_temporary:
		_restore_held_ball_to_stored(ball_key)
	_finalise_gesture(ball_key, release_position, false)


## Kit renders a static icon; releases the ball from tracking before the IN_KIT change reaches BallManager.
func _park_held_ball_in_kit() -> void:
	if not (_held is Ball):
		return
	_ball_manager.clear_loose_in_venue(_held_key)
	(_held as Ball).enter_stored()
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
	rack.refresh()
	return true


func _finalise_gesture(ball_key: String, release_position: Vector2, over_court: bool) -> void:
	# Live-grab path: the Ball survives the gesture or was freed elsewhere; do not free here.
	if _held != null and not (_held is Ball):
		_held.queue_free()

	# A rack-origin gesture that ends back on the rack freed its slot on grab; reclaim one so the
	# next insert sees the slot occupied. Court/venue endings stay slotless.
	if _ended_on_rack(ball_key):
		_ball_manager.reassign_rack_slot(ball_key)

	_reset_gesture_state()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(ball_key, release_position, over_court)


## True when a finalised item sits STORED on the rack (not on court, not loose in the venue).
func _ended_on_rack(ball_key: String) -> bool:
	if ball_key.is_empty():
		return false
	if _ball_manager.get_placement(ball_key) != Placement.STORED:
		return false
	return not _ball_manager.is_loose_in_venue(ball_key)


func _reset_gesture_state() -> void:
	_held = null
	_held_key = ""
	_held_was_on_court = false
	_held_origin = &"rack"
	_held_preserved_speed = PRESERVED_SPEED_NONE
	_cursor_samples.clear()
	_press_position = Vector2.ZERO
	_gesture_below_threshold = true
	_release_pending = false


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


## Raw viewport mouse position, unlike _cursor_position/_event_world_position which bake in the
## VenueCamera's pan offset; Kit lives in a CanvasLayer and hit-tests in this space instead.
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


func _on_rack_slot_pressed(ball_key: String, _slot_press_position: Vector2) -> void:
	grab_from_rack(ball_key)
	rack.refresh.call_deferred()


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
	if rack != null:
		rack.hide_slot_for(ball_key)
	kit.hide_slot_for(ball_key)


func _on_drop_completed(ball_key: String, _release_position: Vector2, _over_court: bool) -> void:
	# Loose-in-venue items have their rack entry filtered out by BallManager.get_stored_items; nothing to reveal.
	if _ball_manager.is_loose_in_venue(ball_key):
		return
	if rack != null:
		rack.reveal_slot_for(ball_key)
	kit.reveal_slot_for(ball_key)
