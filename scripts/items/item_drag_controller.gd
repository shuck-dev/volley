class_name ItemDragController
extends Node2D

## Owns the held-body during a drag gesture and polls every registered DropTarget for a valid commit.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, release_position: Vector2, over_court: bool)
const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")
const CharacterDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/character_drop_target.gd"
)

const CURSOR_SAMPLE_WINDOW: float = 0.08
const PRESERVED_SPEED_NONE: float = -1.0
## Minimum cursor travel before a rack-origin gesture counts as a real drag.
const COMMIT_MOVEMENT_THRESHOLD_PX: float = 6.0

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var gear_rack: RackDisplay
@export var gear_rack_drop_target: Area2D
@export var timeout_controller: TimeoutController
@export var venue_bounds: Rect2 = Rect2()
@export var court_bounds: Rect2 = Rect2()
@export var reconciler: BallReconciler
@export var cursor_overlay: BallDropOverlay

var _item_manager: Node
## Held body during a drag gesture (HeldBody for rack/temp grabs, Ball for live grabs).
var _held: Node2D = null
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
var _cursor_state: int = CursorStateScript.State.DEFAULT
var _release_pending: bool = false

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

	_register_builtin_targets()


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
		if not attempt_release(cursor_target):
			pass
	else:
		if _held is HeldBody and (_held as HeldBody).phase == HeldBody.Phase.LIFTING:
			(_held as HeldBody).mark_held()


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
	if not attempt_release(_event_world_position(mouse_button)):
		# Gesture stays alive: keep following the cursor and retry release each frame.
		_release_pending = true


func is_dragging() -> bool:
	return _drag_target() != null


## Returns the active drag-target node for cursor follow
func _drag_target() -> Node2D:
	# A dev-only remove_level can free the held ball mid-gesture; drop the dangling ref.
	if _held is Ball and not is_instance_valid(_held):
		_held = null
	return _held


func get_held_key() -> String:
	return _held_key


func get_held_body() -> HeldBody:
	return _held as HeldBody


func get_cursor_state() -> int:
	return _cursor_state


## Lets subsystems with their own area resources (Shop) join the target poll without owning the held body.
func register_target(target: DropTarget) -> void:
	if target == null:
		return
	add_child(target)


func unregister_target(target: DropTarget) -> void:
	remove_child(target)
	target.queue_free()


func get_registered_targets() -> Array[DropTarget]:
	var result: Array[DropTarget] = []
	for child in get_children():
		if child is DropTarget:
			result.append(child as DropTarget)
	return result


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
		# The one-shot kit reconcile can leave a second stored ball untracked; back-fill it so a
		# ball-role rack pickup rides the live-ball path and restore re-claims its slot.
		if stored == null and _is_ball_role(item_key):
			stored = reconciler.ensure_stored_ball_for_key(item_key)

	if stored != null:
		# Ball-role rack pickup: the STORED Ball IS the drag target. No HeldBody spawn; the ball
		# stays in _balls_by_key, transitioned to OUT_HELD until release.
		stored.enter_out_held()
		_set_court_exclude_rids([stored.get_rid()])
		_adopt_live_ball_as_held(stored, item_key)
	elif not _spawn_held_body(item_key, spawn_position, false):
		# Equipment-role rack pickup still rides HeldBody; the shop spawn path retires it in a future step.
		return false

	# Free the slot while held so a concurrent insert fills from slot 0; restore re-assigns it.
	_item_manager.release_rack_slot(item_key)

	_held_was_on_court = false
	_held_origin = &"rack"
	# A grab only happens on a press; assume mouse is down so polling waits for mouse-up.
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


## Press on an equipped item: spawn a HeldBody and start a drag whose cancel re-equips through the capacity gate.
## Allowed only at the equip pose; the gesture does not begin during a rally or between-rally lulls.
func grab_equipped_from_character(item_key: String, press_position: Variant = null) -> bool:
	if not RallyGate.removal_allowed(timeout_controller):
		return false
	if _drag_target() != null:
		return false
	if _item_manager.get_level(item_key) <= 0:
		return false
	if _item_manager.get_placement(item_key) != Placement.EQUIPPED:
		return false

	var spawn_position: Vector2 = (
		press_position if press_position is Vector2 else _cursor_position()
	)
	if not _spawn_held_body(item_key, spawn_position, false):
		return false

	# Deactivate the moment the item leaves the character so its effect ends at removal, not at drop.
	_item_manager.unequip(item_key)
	# `equipped` origin re-equips on cancel (capacity re-checked); on_court keeps rack/timeout drops honest.
	_held_was_on_court = true
	_held_origin = &"equipped"
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
	var was_on_court: bool = _item_manager.is_on_court(item_key)
	# OUT_REST pickup also routes through here; clear the loose-in-venue overlay so a release-over-rack
	# (or any non-venue target) restores the slot exactly like a live-grab originating from the court.
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
	_held = ball
	_held_key = item_key
	_held_is_temporary = false
	_press_position = spawn_position
	_gesture_below_threshold = true
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
	_item_manager.mark_loose_in_venue(item_key, world_position)


## Equipment attempt_release: rehome the in-flight HeldBody as loose at the release point.
func _release_held_body_as_loose(release_position: Vector2) -> void:
	if not (_held is HeldBody):
		return
	# Equipment leaving the body must deactivate effects; otherwise the stat impact survives
	# the held-into-venue transition because placement never funnels through STORED.
	if _item_manager.get_placement(_held_key) == Placement.EQUIPPED:
		_item_manager.unequip(_held_key)
	var release_velocity: Vector2 = _compute_release_velocity()
	var body: HeldBody = _held as HeldBody
	var host: Node = get_loose_body_host()
	if host != null and body.get_parent() != host:
		body.reparent(host)
	body.global_position = release_position
	body.go_loose(release_velocity)
	register_loose_body(body)
	# Drop the handle so finalisation does not free the loose body.
	_held = null


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

	var item_key: String = _held_key
	var was_temporary: bool = _held_is_temporary
	var has_live_ball: bool = _held is Ball

	# Direct callers bypass _process; re-check distance to keep the no-op gate honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			release_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)

	# Rack-origin press-and-release without movement cancels back to source instead of activating.
	if below_threshold and _held_origin == &"rack" and not _held_was_on_court and not was_temporary:
		if has_live_ball:
			_restore_held_ball_to_stored(item_key)
		_finalise_gesture(item_key, release_position, false)
		return true

	var target: DropTarget = _find_accepting_target(item_key, release_position, 1.0)
	if target == null:
		return false

	if target is CourtDropTarget:
		var velocity: Vector2 = _compute_release_velocity()
		if was_temporary:
			# Temporary balls bypass the reconciler so they don't survive the gesture.
			pass
		elif has_live_ball:
			# Same Ball survives the gesture; transition OUT_HELD → PLAY in place at the release point.
			_release_live_ball_to_court(release_position, velocity)
		else:
			target.accept(item_key, release_position, velocity)
			_apply_preserved_speed_after_accept(item_key)
	elif target is VenueDropTarget:
		if was_temporary:
			# Temporary balls never join the registry; fall through to finalise (which frees the HeldBody).
			pass
		elif _is_ball_role(item_key):
			_release_to_rest(item_key, release_position, _compute_release_velocity())
		else:
			# Equipment keeps the HeldBody loose path; rehome the existing held body rather than spawning a new one.
			_release_held_body_as_loose(release_position)
		_finalise_gesture(item_key, release_position, false)
		return true
	else:
		# Restore is the safety net when ItemManager was already STORED so accept's deactivate was a no-op.
		target.accept(item_key, release_position, Vector2.ZERO)
		if has_live_ball:
			_restore_held_ball_to_stored(item_key)

	var over_court: bool = target is CourtDropTarget
	if was_temporary:
		over_court = false
	_finalise_gesture(item_key, release_position, over_court)
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
	if ball.effect_processor != null:
		ball.effect_processor.sync_base_speed()
	# Keep ItemManager in sync: a rack-origin gesture leaves placement=STORED until activate runs.
	if not _item_manager.is_on_court(_held_key):
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
	_item_manager.mark_loose_in_venue(body.item_key, body.global_position)
	if not body.tree_exited.is_connected(_on_loose_body_freed):
		body.tree_exited.connect(_on_loose_body_freed.bind(body.item_key))


## Public accessor for the venue-scoped node loose bodies parent under so they survive transient scenes (Shop teardown).
func get_loose_body_host() -> Node:
	return _loose_body_host()


## Returns true if a release at `world_position` would be accepted by the court drop target.
func can_court_accept_at(item_key: String, world_position: Vector2) -> bool:
	for child in get_children():
		if child is CourtDropTarget:
			var target: CourtDropTarget = child as CourtDropTarget
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
	_item_manager.clear_loose_in_venue(item_key)
	_adopt_loose_body_as_held(body)

	_held = body
	_held_key = item_key
	_held_is_temporary = false
	_held_was_on_court = false
	_held_origin = &"live"
	_press_position = spawn_position
	_gesture_below_threshold = true
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
		body.reparent(self)


func _loose_body_host() -> Node:
	if reconciler != null:
		return reconciler
	# No reconciler: the controller hosts the loose body itself rather than climbing to its parent.
	return self


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
	for child in get_children():
		var target: DropTarget = child as DropTarget
		if target == null:
			continue
		if target.can_accept(item_key, world_position, scale_factor):
			return target
	return null


## Returns a held Ball to its rack slot in STORED state; safety net when rack accept's deactivate is a no-op.
func _restore_held_ball_to_stored(item_key: String) -> void:
	if not (_held is Ball):
		return
	# Live OUT_REST → rack-drop carries a loose-in-venue overlay that would otherwise hide the restored slot.
	_item_manager.clear_loose_in_venue(item_key)
	# Rack pickups freed the slot on grab; re-claim one before reading the slot position.
	_item_manager.reassign_rack_slot(item_key)
	(_held as Ball).enter_stored()
	if rack != null:
		(_held as Ball).global_position = rack.get_slot_position_for(item_key)


func _finalise_gesture(item_key: String, release_position: Vector2, over_court: bool) -> void:
	# Live-grab path: the Ball survives or was queue_freed by the reconciler via court_changed; do not free here.
	if _held is HeldBody:
		(_held as HeldBody).queue_free()

	# A rack-origin gesture that ends back on the rack freed its slot on grab; reclaim one so the
	# next insert sees the slot occupied. Court/venue endings stay slotless.
	if _ended_on_rack(item_key):
		_item_manager.reassign_rack_slot(item_key)

	_reset_gesture_state()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(item_key, release_position, over_court)


## True when a finalised item sits STORED on the rack (not on court, not loose in the venue).
func _ended_on_rack(item_key: String) -> bool:
	if _item_manager.get_placement(item_key) != Placement.STORED:
		return false
	return not _item_manager.is_loose_in_venue(item_key)


func _reset_gesture_state() -> void:
	_held = null
	_held_key = ""
	_held_is_temporary = false
	_held_was_on_court = false
	_held_origin = &"rack"
	_held_preserved_speed = PRESERVED_SPEED_NONE
	_cursor_samples.clear()
	_press_position = Vector2.ZERO
	_gesture_below_threshold = true
	_release_pending = false
	_set_court_exclude_rids([])


func _set_court_exclude_rids(rids: Array[RID]) -> void:
	for child in get_children():
		if child is CourtDropTarget:
			(child as CourtDropTarget).set_exclude_rids(rids)
			return


func _spawn_held_body(item_key: String, spawn_position: Vector2, is_temporary: bool) -> bool:
	var definition: ItemDefinition = _get_item_definition(item_key)
	var target_scale: Vector2 = Vector2.ONE
	if definition != null:
		target_scale = definition.token_scale

	var body: HeldBody = HeldBody.make_for(definition, item_key)
	if body == null:
		return false
	body.global_position = spawn_position
	body.scale = target_scale
	add_child(body)

	_held = body
	_held_key = item_key
	_held_is_temporary = is_temporary
	_press_position = spawn_position
	_gesture_below_threshold = true
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)
	return true


## Wires the character drop area once the player paddle is spawned; rebuilds the priority list so the character target slots in after court.
func set_character_drop_target(area: Area2D, paddle: Node = null) -> void:
	for child in get_children():
		if child is CharacterDropTarget:
			var target: CharacterDropTarget = child as CharacterDropTarget
			target.configure(_item_manager, area, timeout_controller, paddle)
			_character_target = target
			if not target.equipped_art_pressed.is_connected(_on_equipped_art_pressed):
				target.equipped_art_pressed.connect(_on_equipped_art_pressed)
			return


## Priority order: character equip, role-aware racks, court projection, venue catch-all last.
func _register_builtin_targets() -> void:
	for child in get_children():
		if child is DropTarget:
			remove_child(child)
			child.queue_free()
	_character_target = null

	for target: DropTarget in [
		CharacterDropTarget.new(),
		_make_rack_target(rack_drop_target, &"ball"),
		_make_rack_target(gear_rack_drop_target, &"equipment"),
		_make_court_target(),
		_make_venue_target(),
	]:
		if target == null:
			continue
		add_child(target)


func _make_court_target() -> CourtDropTarget:
	if reconciler == null:
		return null
	var court_target: CourtDropTarget = CourtDropTarget.new()
	court_target.configure(_item_manager, reconciler, get_world_2d(), court_bounds)
	return court_target


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
	venue_target.configure(_item_manager, reconciler, venue_bounds)
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


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key or BallKey.is_instance(item.key, item_key):
			return item
	return null


func _update_cursor_state(world_position: Vector2) -> void:
	var state: int = _derive_cursor_state(world_position)
	_set_cursor_state(state, world_position)


func _derive_cursor_state(world_position: Vector2) -> int:
	if _drag_target() == null:
		return CursorStateScript.State.DEFAULT
	if _position_accepted_by_any_target(_held_key, world_position):
		return CursorStateScript.State.CAN_DROP
	return CursorStateScript.State.FORBIDDEN


func _position_accepted_by_any_target(item_key: String, world_position: Vector2) -> bool:
	if item_key.is_empty():
		return false
	return _find_accepting_target(item_key, world_position, 1.0) != null


func _set_cursor_state(state: int, world_position: Vector2) -> void:
	_cursor_state = state
	BallDropOverlay.update_state(state, world_position)


func _on_rack_slot_pressed(item_key: String, press_position: Vector2) -> void:
	grab_from_rack(item_key, press_position)
	rack.refresh()


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
	if _item_manager.is_loose_in_venue(item_key):
		return
	if rack != null:
		rack.reveal_slot_for(item_key)
	if gear_rack != null:
		gear_rack.reveal_slot_for(item_key)
	if _character_target != null:
		# Grab-time unequip already freed the visual; this reveal targets the snap-back case still EQUIPPED.
		_character_target.set_equipped_visual_visibility(item_key, true)


func _on_equipped_art_pressed(item_key: String) -> void:
	grab_equipped_from_character(item_key)


func _on_loose_body_freed(item_key: String) -> void:
	# Body left the tree (queue_free or re-grab adoption); clearing restores the slot via refresh.
	# Re-grab paths immediately re-hide via pickup_started so any single-frame flicker is masked.
	if is_instance_valid(_item_manager):
		_item_manager.clear_loose_in_venue(item_key)
	if rack != null:
		rack.reveal_slot_for(item_key)
	if gear_rack != null:
		gear_rack.reveal_slot_for(item_key)
