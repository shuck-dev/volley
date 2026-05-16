class_name BallDragController
extends Node2D

## Owns the held-body during a drag gesture and polls every registered DropTarget for a valid commit.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, release_position: Vector2, over_court: bool)
signal cursor_state_changed(state: int, world_position: Vector2)

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")
const CharacterDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/character_drop_target.gd"
)
const PlacementScript: GDScript = preload("res://scripts/items/placement.gd")

const CURSOR_SAMPLE_WINDOW: float = 0.08
const PRESERVED_SPEED_NONE: float = -1.0
## Minimum cursor travel before a rack-origin gesture counts as a real drag.
const COMMIT_MOVEMENT_THRESHOLD_PX: float = 6.0
const HOVER_SCALE_BUMP: Vector2 = Vector2(1.08, 1.08)
const HOVER_MODULATE: Color = Color(1.15, 1.15, 1.15, 1.0)
const NEUTRAL_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var grab_ease_duration_s: float = 0.08
@export var grab_ease_start_scale: Vector2 = Vector2(0.85, 0.85)
@export var grab_ease_start_modulate: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var grab_ease_end_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var gear_rack: RackDisplay
@export var gear_rack_drop_target: Area2D
@export var timeout_controller: TimeoutController
@export var court_bounds: Rect2 = Rect2()
@export var venue_bounds: Rect2 = Rect2()
@export var reconciler: BallReconciler
@export var cursor_overlay: CursorOverlay
@export var expansion_ring_hold_s: float = 0.25
@export var expansion_ring_scale: float = 1.5

var _item_manager: Node
var _held_body: HeldBody = null
## Live-grab keeps the existing Ball alive across the gesture; rack/temp grabs spawn a HeldBody instead.
var _held_ball: Ball = null
var _held_key: String = ""
var _held_is_temporary: bool = false
var _held_was_on_court: bool = false
## &"rack" or &"live"; rack origins gate the click-without-movement no-op.
var _held_origin: StringName = &"rack"
var _cursor_samples: Array = []
var _press_position: Vector2 = Vector2.ZERO
var _gesture_below_threshold: bool = true
var _mouse_button_down: bool = false
## Negative means no preserved energy; positive carries rally speed across grab+release.
var _held_preserved_speed: float = PRESERVED_SPEED_NONE
var _grab_origin_position: Vector2 = Vector2.ZERO
var _grab_ease_elapsed: float = 0.0
var _grab_target_scale: Vector2 = Vector2.ONE
var _cursor_state: int = CursorStateScript.State.DEFAULT
## Negative means expansion-ring polling has not started timing yet.
var _expansion_started_at: float = -1.0
## True after a real player mouse-up while no drop target accepted; the gesture stays alive following the cursor.
var _release_pending: bool = false

var _drop_targets: Array[DropTarget] = []
## Built-ins are rebuilt on `_ready` and ignored by `unregister_target`.
var _builtin_targets: Array[DropTarget] = []

## Set after the player paddle spawns so the character target can find a live Area2D.
var _character_drop_area: Area2D
var _character_target: CharacterDropTargetScript = null


func configure(
	item_manager: Node,
	rack_display: RackDisplay,
	drop_area: Area2D,
	ball_reconciler: BallReconciler,
) -> void:
	_item_manager = item_manager
	rack = rack_display
	rack_drop_target = drop_area
	reconciler = ball_reconciler


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager

	# Group lookup so Shop can hand presses to the controller without a NodePath.
	add_to_group(&"drag_controller")

	if rack != null and not rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		rack.slot_pressed.connect(_on_rack_slot_pressed)

	if gear_rack != null and not gear_rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		gear_rack.slot_pressed.connect(_on_rack_slot_pressed)

	# Hide rack slots while their item is held so the player sees one body, not two.
	if not pickup_started.is_connected(_on_pickup_started):
		pickup_started.connect(_on_pickup_started)
	if not drop_completed.is_connected(_on_drop_completed):
		drop_completed.connect(_on_drop_completed)

	if reconciler != null:
		if not reconciler.ball_spawned.is_connected(_on_reconciler_ball_spawned):
			reconciler.ball_spawned.connect(_on_reconciler_ball_spawned)

	if cursor_overlay != null:
		if not cursor_state_changed.is_connected(cursor_overlay.set_state):
			cursor_state_changed.connect(cursor_overlay.set_state)

	_register_builtin_targets()


func _process(delta: float) -> void:
	var drag_target: Node2D = _drag_target()
	if drag_target == null:
		_set_cursor_state(CursorStateScript.State.DEFAULT, _cursor_position())
		return

	var cursor_target: Vector2 = _clamp_to_venue(_cursor_position())
	_grab_ease_elapsed = minf(_grab_ease_elapsed + delta, grab_ease_duration_s)
	var ease_progress: float = _grab_ease_progress()
	_apply_grab_ease(ease_progress, cursor_target)

	var follow_position: Vector2 = drag_target.global_position
	_track_cursor_motion(follow_position)
	if _gesture_below_threshold:
		if follow_position.distance_to(_press_position) >= COMMIT_MOVEMENT_THRESHOLD_PX:
			_gesture_below_threshold = false

	_update_cursor_state(follow_position)

	if not _mouse_button_down:
		# Release-pending gestures retry at the cursor every frame so the player can drag
		# to a valid spot after a wall-pinned release; never auto-cancel to source.
		var release_target: Vector2 = cursor_target if _release_pending else follow_position
		if not attempt_release(release_target):
			if _release_pending:
				_update_hover_feedback(release_target)
			else:
				_update_expansion_state(follow_position)
	elif ease_progress >= 1.0:
		# Hover feedback is suppressed until the lift ease settles to avoid mid-tween bumps.
		_update_hover_feedback(follow_position)


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
	if not attempt_release(_clamp_to_venue(_event_world_position(mouse_button))):
		# Gesture stays alive: keep following the cursor and retry release each frame.
		_release_pending = true


func is_dragging() -> bool:
	return _drag_target() != null


## Returns the active drag-target node for cursor follow / ease / hover; HeldBody for rack+temp grabs, Ball for live grabs.
func _drag_target() -> Node2D:
	if _held_ball != null:
		return _held_ball
	return _held_body


func get_held_key() -> String:
	return _held_key


func get_held_body() -> HeldBody:
	return _held_body


func get_cursor_state() -> int:
	return _cursor_state


## Lets subsystems with their own area resources (Shop) join the target poll without owning the held body.
func register_target(target: DropTarget) -> void:
	if target == null:
		return
	if _drop_targets.has(target):
		return
	_drop_targets.append(target)


func unregister_target(target: DropTarget) -> void:
	if _builtin_targets.has(target):
		return
	_drop_targets.erase(target)


func get_registered_targets() -> Array[DropTarget]:
	return _drop_targets.duplicate()


## Activation defers to release-over-court so a click-without-movement is a no-op.
func grab_from_rack(item_key: String, press_position: Variant = null) -> bool:
	if _drag_target() != null:
		return false
	if _item_manager.get_level(item_key) <= 0:
		return false
	if _item_manager.is_on_court(item_key):
		return false

	var spawn_position: Vector2 = (
		press_position if press_position is Vector2 else _cursor_position()
	)

	var stored: Ball = null
	if reconciler != null:
		stored = reconciler.get_ball_for_key(item_key)

	if stored != null:
		# Ball-role rack pickup: the STORED Ball IS the drag target. No HeldBody spawn; the ball
		# stays in _balls_by_key, transitioned to OUT_HELD until release.
		stored.enter_out_held()
		_set_court_exclude_rids([stored.get_rid()])
		_adopt_live_ball_as_held(stored, item_key)
	elif not _spawn_held_body(item_key, spawn_position, false):
		# Equipment-role rack pickup still rides HeldBody; the shop spawn path retires it in a future step.
		return false

	_held_was_on_court = false
	_held_origin = &"rack"
	# A grab only happens on a press; assume mouse is down so polling waits for mouse-up.
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


## Press on the mounted equipped art: spawn a HeldBody for the equipment and start a drag whose cancel restores EQUIPPED.
func grab_equipped_from_character(item_key: String, press_position: Variant = null) -> bool:
	if _drag_target() != null:
		return false
	if _item_manager == null or _item_manager.get_level(item_key) <= 0:
		return false
	if _item_manager.get_placement(item_key) != PlacementScript.EQUIPPED:
		return false

	var spawn_position: Vector2 = (
		press_position if press_position is Vector2 else _cursor_position()
	)
	if not _spawn_held_body(item_key, spawn_position, false):
		return false

	# `live` + on_court so an expansion-ring timeout routes through deactivate (= unequip);
	# Rack drops also call unequip via RackDropTarget. Non-accepting drops keep EQUIPPED intact.
	_held_was_on_court = true
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


func grab_live_ball(item_key: String, is_temporary: bool = false) -> bool:
	if _drag_target() != null:
		return false

	var existing: Ball = null
	if reconciler != null:
		existing = reconciler.get_ball_for_key(item_key)

	# Temporary balls bypass the reconciler; spawn a HeldBody so the gesture does not survive into a tracked entity.
	if is_temporary:
		if not _spawn_held_body(item_key, _cursor_position(), is_temporary):
			return false
		_held_was_on_court = false
		_held_origin = &"live"
		_mouse_button_down = true
		pickup_started.emit(item_key)
		return true

	if existing == null:
		return false

	# Capture on-court state before clearing the overlay; OUT_REST cancels must skip deactivate.
	var was_on_court: bool = _item_manager != null and _item_manager.is_on_court(item_key)
	# OUT_REST pickup also routes through here; clear the loose-in-venue overlay so a release-over-rack
	# (or any non-venue target) restores the slot exactly like a live-grab originating from the court.
	if _item_manager != null:
		_item_manager.clear_loose_in_venue(item_key)
	existing.enter_out_held()
	# Self-overlap exclusion: the held ball's own body would otherwise reject the release projection.
	_set_court_exclude_rids([existing.get_rid()])
	_adopt_live_ball_as_held(existing, item_key)
	_held_was_on_court = was_on_court
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


func _adopt_live_ball_as_held(ball: Ball, item_key: String) -> void:
	var spawn_position: Vector2 = ball.global_position
	_held_ball = ball
	_held_key = item_key
	_held_is_temporary = false
	_press_position = spawn_position
	_gesture_below_threshold = true
	_grab_origin_position = spawn_position
	_grab_ease_elapsed = 0.0
	# Live grabs keep the ball's existing scale (typically Vector2.ONE; art lives on the ItemArtHolder).
	_grab_target_scale = ball.scale
	_expansion_started_at = -1.0
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)


## Routes a just-purchased item to whatever target accepts the release position; venue/rack/court all valid.
func spawn_purchased_at(
	item_key: String, world_position: Vector2, gesture_velocity: Vector2
) -> bool:
	var target: DropTarget = _find_accepting_target(item_key, world_position, 1.0)
	if target == null:
		return false
	if target is CourtDropTarget:
		target.accept(item_key, world_position, gesture_velocity)
		return true
	if target is VenueDropTarget:
		if _is_ball_role(item_key):
			_release_to_rest(item_key, world_position, gesture_velocity)
		else:
			_release_loose_body_at(item_key, world_position, gesture_velocity)
		return true
	if target is RackDropTarget and _is_ball_role(item_key):
		# Ball-role rack landing adopts a STORED Ball at the slot; rack accept's deactivate branch
		# is a no-op for a just-purchased, not-on-court item.
		_adopt_purchased_into_rack(item_key)
		return true
	target.accept(item_key, world_position, gesture_velocity)
	return true


func _adopt_purchased_into_rack(item_key: String) -> void:
	if reconciler == null or rack == null:
		return
	if reconciler.get_ball_for_key(item_key) != null:
		return
	reconciler.adopt_stored(item_key, rack.get_slot_position_for(item_key))


## Funnels ball-role venue-floor releases into the reconciler with the loose-in-venue overlay set.
func _release_to_rest(item_key: String, world_position: Vector2, gesture_velocity: Vector2) -> void:
	if reconciler == null:
		return
	reconciler.release_into_rest(item_key, world_position, gesture_velocity)
	# Loose-in-venue overlay makes is_on_court return false regardless of placement, so save/reload
	# skips the spurious court-spawn at the saved venue-floor position.
	if _item_manager != null:
		_item_manager.mark_loose_in_venue(item_key, world_position)


## Equipment attempt_release: rehome the in-flight HeldBody as loose at the release point.
func _release_held_body_as_loose(release_position: Vector2) -> void:
	if _held_body == null:
		return
	var release_velocity: Vector2 = _compute_release_velocity()
	var body: HeldBody = _held_body
	var host: Node = get_loose_body_host()
	if host != null and body.get_parent() != host:
		body.get_parent().remove_child(body)
		host.add_child(body)
	body.global_position = release_position
	body.modulate = grab_ease_end_modulate
	body.go_loose(release_velocity)
	register_loose_body(body)
	# Drop the handle so finalisation does not free the loose body.
	_held_body = null


## Spawns a loose HeldBody at the release point and wires re-grab + loose-in-venue overlay.
func _release_loose_body_at(
	item_key: String, world_position: Vector2, gesture_velocity: Vector2
) -> void:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null:
		return
	var body: HeldBody = HeldBody.make_for(definition, item_key)
	if body == null:
		return
	body.global_position = world_position
	var host: Node = get_loose_body_host()
	host.add_child(body)
	body.go_loose(gesture_velocity)
	register_loose_body(body)


func _is_ball_role(item_key: String) -> bool:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null:
		return false
	return definition.role == &"ball"


## Returns false on no valid target so the held body stays with the cursor.
func attempt_release(release_position: Vector2) -> bool:
	if _drag_target() == null:
		return false

	var clamped_position: Vector2 = _clamp_to_venue(release_position)
	var item_key: String = _held_key
	var was_temporary: bool = _held_is_temporary
	var has_live_ball: bool = _held_ball != null

	# Direct callers bypass _process; re-check distance to keep the no-op gate honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			clamped_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)

	# Rack-origin press-and-release without movement cancels back to source instead of activating.
	if below_threshold and _held_origin == &"rack" and not _held_was_on_court and not was_temporary:
		if has_live_ball:
			_restore_held_ball_to_stored(item_key)
		_finalise_gesture(item_key, clamped_position, false)
		return true

	var target: DropTarget = _find_accepting_target(item_key, clamped_position, 1.0)
	if target == null and _expansion_started_at >= 0.0:
		var held_duration: float = _now_seconds() - _expansion_started_at
		if held_duration >= expansion_ring_hold_s:
			target = _find_accepting_target(item_key, clamped_position, expansion_ring_scale)

	if target == null:
		return false

	if target is CourtDropTarget:
		var velocity: Vector2 = _compute_release_velocity()
		if was_temporary:
			# Temporary balls bypass the reconciler so they don't survive the gesture.
			pass
		elif has_live_ball:
			# Same Ball survives the gesture; transition OUT_HELD → PLAY in place at the release point.
			_release_live_ball_to_court(clamped_position, velocity)
		else:
			target.accept(item_key, clamped_position, velocity)
			_apply_preserved_speed_after_accept(item_key)
	elif target is VenueDropTarget:
		if was_temporary:
			# Temporary balls never join the registry; fall through to finalise (which frees the HeldBody).
			pass
		elif _is_ball_role(item_key):
			_release_to_rest(item_key, clamped_position, _compute_release_velocity())
		else:
			# Equipment keeps the HeldBody loose path; rehome the existing held body rather than spawning a new one.
			_release_held_body_as_loose(clamped_position)
		_finalise_gesture(item_key, clamped_position, false)
		return true
	else:
		# Restore is the safety net when ItemManager was already STORED so accept's deactivate was a no-op.
		target.accept(item_key, clamped_position, Vector2.ZERO)
		if has_live_ball:
			_restore_held_ball_to_stored(item_key)

	var over_court: bool = target is CourtDropTarget
	if was_temporary:
		over_court = false
	_finalise_gesture(item_key, clamped_position, over_court)
	return true


# Transitions the held Ball from OUT_HELD → PLAY_NORMAL/PLAY_ARC at the release point with gesture velocity.
func _release_live_ball_to_court(release_position: Vector2, velocity: Vector2) -> void:
	var ball: Ball = _held_ball
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
	if ball.effect_processor != null:
		ball.effect_processor.sync_base_speed()
	# Keep ItemManager in sync: a rack-origin gesture leaves placement=STORED until activate runs.
	if _item_manager != null and not _item_manager.is_on_court(_held_key):
		_item_manager.activate(_held_key)


## Keeps the loose-body helper path alive for Shop's `_drop_falling_body`; venue-floor releases bypass it.
func track_loose_body(body: HeldBody) -> void:
	if not body.grabbed.is_connected(_on_loose_body_grabbed):
		body.grabbed.connect(_on_loose_body_grabbed)


## Folds re-grab wiring, ItemManager loose-in-venue promotion, and slot-restore-on-free into one call.
func register_loose_body(body: HeldBody) -> void:
	if body == null:
		return
	track_loose_body(body)
	if _item_manager != null:
		_item_manager.mark_loose_in_venue(body.item_key, body.global_position)
	if not body.tree_exited.is_connected(_on_loose_body_freed):
		body.tree_exited.connect(_on_loose_body_freed.bind(body.item_key))


## Public accessor for the venue-scoped node loose bodies parent under so they survive transient scenes (Shop teardown).
func get_loose_body_host() -> Node:
	return _loose_body_host()


## Returns true if a release at `world_position` would be accepted by the court drop target.
func can_court_accept_at(item_key: String, world_position: Vector2) -> bool:
	for target: DropTarget in _drop_targets:
		if target is CourtDropTarget:
			if target.can_accept(item_key, world_position, 1.0):
				return true
			return false
	return false


## Re-grabs a loose body the player pressed; reuses the same body so the gesture stays diegetic.
func _on_loose_body_grabbed(body: HeldBody) -> void:
	if _drag_target() != null:
		return
	var item_key: String = body.item_key

	var spawn_position: Vector2 = body.global_position
	body.grabbed.disconnect(_on_loose_body_grabbed)
	# Re-grab consumes the loose-in-venue overlay so the rack reveals normally on the next release path.
	if _item_manager != null:
		_item_manager.clear_loose_in_venue(item_key)
	_adopt_loose_body_as_held(body)

	_held_body = body
	_held_key = item_key
	_held_is_temporary = false
	_held_was_on_court = false
	_held_origin = &"live"
	_press_position = spawn_position
	_gesture_below_threshold = true
	_grab_origin_position = spawn_position
	_grab_ease_elapsed = 0.0
	# Re-grab keeps the loose body's at-rest visual; rack pickups shrink to token_scale instead.
	_grab_target_scale = body.scale
	_expansion_started_at = -1.0
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)
	_mouse_button_down = true
	pickup_started.emit(item_key)


func _adopt_loose_body_as_held(body: HeldBody) -> void:
	body.phase = HeldBody.Phase.LIFTING
	body.linear_velocity = Vector2.ZERO
	body.gravity_scale = 0.0
	body.freeze = true
	body.collision_layer = 0
	body.collision_mask = 0
	body._enable_grab_area(false)
	body.reclaim_scale_from_art_holder()
	# Reparent to the controller so the lift ease and follow-cursor flow handle it like a fresh grab.
	if body.get_parent() != self:
		body.get_parent().remove_child(body)
		add_child(body)


func _loose_body_host() -> Node:
	if reconciler != null:
		return reconciler
	return get_parent()


func _apply_preserved_speed_after_accept(item_key: String) -> void:
	if _held_preserved_speed < 0.0:
		return
	if reconciler == null:
		return
	var ball: Ball = reconciler.get_ball_for_key(item_key)
	if ball == null:
		return
	ball.speed = _held_preserved_speed
	# Re-sync the effect processor's base so the next physics frame's speed-limit clamp
	# does not snap us back to ball_speed_min.
	if ball.effect_processor != null:
		ball.effect_processor.sync_base_speed()
	if ball.linear_velocity.length() > 0.0:
		ball.linear_velocity = ball.linear_velocity.normalized() * _held_preserved_speed


func _find_accepting_target(
	item_key: String, world_position: Vector2, scale_factor: float
) -> DropTarget:
	for target: DropTarget in _drop_targets:
		if target.can_accept(item_key, world_position, scale_factor):
			return target
	return null


func _update_hover_feedback(world_position: Vector2) -> void:
	var drag_target: Node2D = _drag_target()
	if drag_target == null:
		return
	var hovering: bool = _find_accepting_target(_held_key, world_position, 1.0) != null
	# Use the grab's target scale so loose-body re-grabs keep their at-rest size; rack pickups still ride token_scale.
	var base_scale: Vector2 = _grab_target_scale
	if hovering:
		drag_target.scale = base_scale * HOVER_SCALE_BUMP
		drag_target.modulate = HOVER_MODULATE
	else:
		drag_target.scale = base_scale
		drag_target.modulate = NEUTRAL_MODULATE


func _update_expansion_state(world_position: Vector2) -> void:
	if _drag_target() == null:
		return
	if _expansion_started_at < 0.0:
		_expansion_started_at = _now_seconds()
		return

	var held_duration: float = _now_seconds() - _expansion_started_at
	if held_duration < expansion_ring_hold_s:
		return

	var widened: DropTarget = _find_accepting_target(
		_held_key, world_position, expansion_ring_scale
	)
	if widened != null:
		attempt_release(world_position)
		return

	if held_duration >= expansion_ring_hold_s * 2.0:
		_cancel_to_source()


## Routes a timed-out gesture back to its origin: on-court deactivate, OUT_REST unfreeze, or STORED restore.
func _cancel_to_source() -> void:
	var item_key: String = _held_key
	var was_on_court: bool = _held_was_on_court
	var origin: StringName = _held_origin
	var drag_target: Node2D = _drag_target()
	var release_position: Vector2 = (
		drag_target.global_position if drag_target != null else _press_position
	)

	if origin == &"live" and was_on_court:
		if _item_manager != null and _item_manager.is_on_court(item_key):
			_item_manager.deactivate(item_key)
	elif origin == &"live" and _held_ball != null:
		# OUT_REST origin: deactivate is a no-op so unfreeze back to OUT_REST at the cancel point.
		_held_ball.enter_out_rest()
	elif origin == &"rack" and _held_ball != null:
		_restore_held_ball_to_stored(item_key)

	_finalise_gesture(item_key, release_position, false)


## Returns a held Ball to its rack slot in STORED state; safety net when rack accept's deactivate is a no-op.
func _restore_held_ball_to_stored(item_key: String) -> void:
	if _held_ball == null:
		return
	# Live OUT_REST → rack-drop carries a loose-in-venue overlay that would otherwise hide the restored slot.
	if _item_manager != null:
		_item_manager.clear_loose_in_venue(item_key)
	_held_ball.enter_stored()
	if rack != null:
		_held_ball.global_position = rack.get_slot_position_for(item_key)


func _finalise_gesture(item_key: String, release_position: Vector2, over_court: bool) -> void:
	# Live-grab path: the Ball survives or was queue_freed by the reconciler via court_changed; do not free here.
	if _held_body != null:
		_held_body.queue_free()
	_reset_gesture_state()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(item_key, release_position, over_court)


func _reset_gesture_state() -> void:
	_held_body = null
	_held_ball = null
	_held_key = ""
	_held_is_temporary = false
	_held_was_on_court = false
	_held_origin = &"rack"
	_held_preserved_speed = PRESERVED_SPEED_NONE
	_cursor_samples.clear()
	_press_position = Vector2.ZERO
	_gesture_below_threshold = true
	_grab_origin_position = Vector2.ZERO
	_grab_ease_elapsed = 0.0
	_grab_target_scale = Vector2.ONE
	_expansion_started_at = -1.0
	_release_pending = false
	_set_court_exclude_rids([])


func _set_court_exclude_rids(rids: Array[RID]) -> void:
	for target: DropTarget in _drop_targets:
		if target is CourtDropTarget:
			(target as CourtDropTarget).set_exclude_rids(rids)


func _spawn_held_body(item_key: String, spawn_position: Vector2, is_temporary: bool) -> bool:
	var definition: ItemDefinition = _get_item_definition(item_key)
	var target_scale: Vector2 = Vector2.ONE
	if definition != null:
		target_scale = definition.token_scale

	var body: HeldBody = HeldBody.make_for(definition, item_key)
	if body == null:
		return false
	body.global_position = spawn_position
	body.scale = grab_ease_start_scale * target_scale
	body.modulate = grab_ease_start_modulate
	add_child(body)

	_held_body = body
	_held_key = item_key
	_held_is_temporary = is_temporary
	_press_position = spawn_position
	_gesture_below_threshold = true
	_grab_origin_position = spawn_position
	_grab_ease_elapsed = 0.0
	_grab_target_scale = target_scale
	_expansion_started_at = -1.0
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)
	return true


## Wires the character drop area once the player paddle is spawned; rebuilds the priority list so the character target slots in after court.
func set_character_drop_target(area: Area2D) -> void:
	_character_drop_area = area
	_register_builtin_targets()


## Priority order: court strict projection first, character equip, role-aware racks, venue catch-all last.
func _register_builtin_targets() -> void:
	_drop_targets.clear()
	_builtin_targets.clear()
	_character_target = null

	for target: DropTarget in [
		_make_court_target(),
		_make_character_target(),
		_make_rack_target(rack_drop_target, &"ball"),
		_make_rack_target(gear_rack_drop_target, &"equipment"),
		_make_venue_target(),
	]:
		if target == null:
			continue
		_drop_targets.append(target)
		_builtin_targets.append(target)


func _make_court_target() -> CourtDropTarget:
	if reconciler == null:
		return null
	var court_target: CourtDropTarget = CourtDropTarget.new()
	court_target.configure(_item_manager, reconciler, get_world_2d(), court_bounds)
	return court_target


func _make_character_target() -> DropTarget:
	if _character_drop_area == null or timeout_controller == null:
		return null
	var character_target: CharacterDropTargetScript = CharacterDropTargetScript.new()
	character_target.configure(_item_manager, _character_drop_area, timeout_controller)
	# Track the live target so equipped-art presses route into grab_equipped_from_character.
	_character_target = character_target
	if not character_target.equipped_art_pressed.is_connected(_on_equipped_art_pressed):
		character_target.equipped_art_pressed.connect(_on_equipped_art_pressed)
	return character_target


func _make_rack_target(area: Area2D, role: StringName) -> RackDropTarget:
	if area == null:
		return null
	var rack_target: RackDropTarget = RackDropTarget.new()
	rack_target.configure(_item_manager, area, role)
	return rack_target


func _make_venue_target() -> VenueDropTarget:
	if reconciler == null:
		return null
	var venue_target: VenueDropTarget = VenueDropTarget.new()
	venue_target.configure(_item_manager, reconciler, venue_bounds, court_bounds)
	# Body projection on the venue rect rejects loose drops that would land in walls/partners.
	venue_target.set_world(get_world_2d())
	return venue_target


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
		return _item_manager.get_default_ball_launch_velocity()

	var first: Dictionary = _cursor_samples[0]
	var last: Dictionary = _cursor_samples[_cursor_samples.size() - 1]
	var time_delta: float = float(last["time"]) - float(first["time"])
	if time_delta <= 0.0:
		return _item_manager.get_default_ball_launch_velocity()

	var pos_delta: Vector2 = Vector2(last["position"]) - Vector2(first["position"])
	var velocity: Vector2 = pos_delta / time_delta
	if velocity.length() < 1.0:
		return _item_manager.get_default_ball_launch_velocity()
	return velocity


func _cursor_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return global_position
	return get_global_mouse_position()


func _event_world_position(event: InputEventMouseButton) -> Vector2:
	var canvas_transform: Transform2D = get_canvas_transform()
	return canvas_transform.affine_inverse() * event.position


func _clamp_to_venue(world_position: Vector2) -> Vector2:
	return DropTarget.clamp_to_rect(world_position, venue_bounds)


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null


func _now_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _grab_ease_progress() -> float:
	if grab_ease_duration_s <= 0.0:
		return 1.0
	return clampf(_grab_ease_elapsed / grab_ease_duration_s, 0.0, 1.0)


func _apply_grab_ease(progress: float, cursor_target: Vector2) -> void:
	var drag_target: Node2D = _drag_target()
	if drag_target == null:
		return
	# Cubic ease-out: 1 - (1 - t)^3.
	var inv: float = 1.0 - progress
	var eased: float = 1.0 - inv * inv * inv
	drag_target.global_position = _grab_origin_position.lerp(cursor_target, eased)
	drag_target.scale = (grab_ease_start_scale * _grab_target_scale).lerp(_grab_target_scale, eased)
	drag_target.modulate = grab_ease_start_modulate.lerp(grab_ease_end_modulate, eased)
	if progress >= 1.0 and _held_body != null and _held_body.phase == HeldBody.Phase.LIFTING:
		_held_body.mark_held()


func _update_cursor_state(world_position: Vector2) -> void:
	var state: int = _derive_cursor_state(world_position)
	_set_cursor_state(state, world_position)


func _derive_cursor_state(world_position: Vector2) -> int:
	if _drag_target() == null:
		return CursorStateScript.State.DEFAULT
	# The held body is clamped to venue but the raw cursor can drift outside.
	if not _is_within_venue(_cursor_position()):
		return CursorStateScript.State.FORBIDDEN
	if _position_accepted_by_any_target(_held_key, world_position):
		return CursorStateScript.State.CAN_DROP
	return CursorStateScript.State.DRAGGING


func _position_accepted_by_any_target(item_key: String, world_position: Vector2) -> bool:
	if item_key.is_empty():
		return false
	return _find_accepting_target(item_key, world_position, 1.0) != null


func _is_within_venue(world_position: Vector2) -> bool:
	if venue_bounds.size == Vector2.ZERO:
		return true
	return venue_bounds.has_point(world_position)


func _set_cursor_state(state: int, world_position: Vector2) -> void:
	_cursor_state = state
	cursor_state_changed.emit(state, world_position)


func _on_rack_slot_pressed(item_key: String, press_position: Vector2) -> void:
	grab_from_rack(item_key, press_position)


func _on_reconciler_ball_spawned(item_key: String, ball: Ball) -> void:
	ball.grabbed.connect(_on_live_ball_grabbed.bind(item_key))


func _on_live_ball_grabbed(_ball: Ball, item_key: String) -> void:
	grab_live_ball(item_key, false)


func _on_pickup_started(item_key: String) -> void:
	if rack != null:
		rack.hide_slot_for(item_key)
	if gear_rack != null:
		gear_rack.hide_slot_for(item_key)
	if _character_target != null:
		_character_target.set_equipped_visual_visibility(item_key, false)


func _on_drop_completed(item_key: String, _release_position: Vector2, _over_court: bool) -> void:
	# Loose-in-venue items have their rack entry filtered out by ItemManager.get_kit_items; nothing to reveal.
	if _item_manager != null and _item_manager.is_loose_in_venue(item_key):
		return
	if rack != null:
		rack.reveal_slot_for(item_key)
	if gear_rack != null:
		gear_rack.reveal_slot_for(item_key)
	if _character_target != null:
		# Visual was freed by the EQUIPPED -> STORED signal handler on a successful unequip;
		# this reveal targets the survive-and-snap-back case where placement is still EQUIPPED.
		_character_target.set_equipped_visual_visibility(item_key, true)


func _on_equipped_art_pressed(item_key: String) -> void:
	grab_equipped_from_character(item_key)


func _on_loose_body_freed(item_key: String) -> void:
	# Body left the tree (queue_free or re-grab adoption); clearing restores the slot via refresh.
	# Re-grab paths immediately re-hide via pickup_started so any single-frame flicker is masked.
	if _item_manager != null:
		_item_manager.clear_loose_in_venue(item_key)
	if rack != null:
		rack.reveal_slot_for(item_key)
	if gear_rack != null:
		gear_rack.reveal_slot_for(item_key)
