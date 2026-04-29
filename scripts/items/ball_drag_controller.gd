class_name BallDragController
extends Node2D

## Owns the held-body during a drag gesture and polls every registered DropTarget for a valid commit.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, release_position: Vector2, over_court: bool)
signal cursor_state_changed(state: int, world_position: Vector2)

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")

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
@export var court_bounds: Rect2 = Rect2()
@export var venue_bounds: Rect2 = Rect2()
@export var reconciler: BallReconciler
@export var cursor_overlay: CursorOverlay
@export var expansion_ring_hold_s: float = 0.25
@export var expansion_ring_scale: float = 1.5

var _item_manager: Node
var _held_body: HeldBody = null
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

var _drop_targets: Array[DropTarget] = []
## Built-ins are rebuilt on `_ready` and ignored by `unregister_target`.
var _builtin_targets: Array[DropTarget] = []


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
	if _held_body == null:
		_set_cursor_state(CursorStateScript.State.DEFAULT, _cursor_position())
		return

	var cursor_target: Vector2 = _clamp_to_venue(_cursor_position())
	_grab_ease_elapsed = minf(_grab_ease_elapsed + delta, grab_ease_duration_s)
	var ease_progress: float = _grab_ease_progress()
	_apply_grab_ease(ease_progress, cursor_target)

	var follow_position: Vector2 = _held_body.global_position
	_track_cursor_motion(follow_position)
	if _gesture_below_threshold:
		if follow_position.distance_to(_press_position) >= COMMIT_MOVEMENT_THRESHOLD_PX:
			_gesture_below_threshold = false

	_update_cursor_state(follow_position)

	if not _mouse_button_down:
		if not attempt_release(follow_position):
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
	if mouse_button.pressed or _held_body == null:
		return

	# Use event position so a Camera2D in the venue doesn't break rack hit-testing.
	if not attempt_release(_clamp_to_venue(_event_world_position(mouse_button))):
		_expansion_started_at = _now_seconds()


func is_dragging() -> bool:
	return _held_body != null


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
	if _held_body != null:
		return false
	if _item_manager.get_level(item_key) <= 0:
		return false
	if _item_manager.is_on_court(item_key):
		return false

	var spawn_position: Vector2 = (
		press_position if press_position is Vector2 else _cursor_position()
	)
	_spawn_held_body(item_key, spawn_position, false)
	_held_was_on_court = false
	_held_origin = &"rack"
	# A grab only happens on a press; assume mouse is down so polling waits for mouse-up.
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


func grab_live_ball(item_key: String, is_temporary: bool = false) -> bool:
	if _held_body != null:
		return false

	var existing: Ball = null
	if reconciler != null:
		existing = reconciler.get_ball_for_key(item_key)

	var spawn_position: Vector2 = _cursor_position()
	if existing != null:
		spawn_position = existing.global_position
		# Capture rally speed before freeing the live ball so the released ball inherits it.
		_held_preserved_speed = existing.speed
		if reconciler != null:
			reconciler.release_ball(item_key)
		# The frozen body lingers a frame before queue_free settles; exclude its RID so
		# the projection at release does not self-overlap and snap the cursor off-court.
		_set_court_exclude_rids([existing.get_rid()])
		existing.freeze = true
		existing.call_deferred("queue_free")

	_spawn_held_body(item_key, spawn_position, is_temporary)
	_held_was_on_court = not is_temporary
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


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
		# Venue accepts as a loose-body release; spawn a HeldBody and let it fall.
		_spawn_loose_body_at(item_key, world_position, gesture_velocity)
		return true
	# Rack/shop targets accept by activating; the ball reconciler handles the live spawn.
	target.accept(item_key, world_position, gesture_velocity)
	return true


func _spawn_loose_body_at(
	item_key: String, world_position: Vector2, gesture_velocity: Vector2
) -> void:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null:
		return
	var body: HeldBody = HeldBody.make_for(definition, item_key)
	body.global_position = world_position
	var host: Node = _loose_body_host()
	host.add_child(body)
	body.go_loose(gesture_velocity)
	track_loose_body(body)


## Returns false on no valid target so the held body stays with the cursor.
func attempt_release(release_position: Vector2) -> bool:
	if _held_body == null:
		return false

	var clamped_position: Vector2 = _clamp_to_venue(release_position)
	var item_key: String = _held_key
	var was_temporary: bool = _held_is_temporary

	# Direct callers bypass _process; re-check distance to keep the no-op gate honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			clamped_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)

	# Rack-origin press-and-release without movement cancels back to source instead of activating.
	if below_threshold and _held_origin == &"rack" and not _held_was_on_court and not was_temporary:
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
		else:
			target.accept(item_key, clamped_position, velocity)
			_apply_preserved_speed_after_accept(item_key)
	elif target is VenueDropTarget:
		_release_loose(clamped_position, was_temporary)
		_finalise_loose_gesture(item_key, clamped_position, false)
		return true
	else:
		target.accept(item_key, clamped_position, Vector2.ZERO)

	var over_court: bool = target is CourtDropTarget
	if was_temporary:
		over_court = false
	_finalise_gesture(item_key, clamped_position, over_court)
	return true


func _release_loose(release_position: Vector2, was_temporary: bool) -> void:
	if _held_body == null or was_temporary:
		return
	var release_velocity: Vector2 = _compute_release_velocity()
	var body: HeldBody = _held_body
	var host: Node = _loose_body_host()
	if host != null and body.get_parent() != host:
		body.get_parent().remove_child(body)
		host.add_child(body)
	body.global_position = release_position
	body.modulate = grab_ease_end_modulate
	body.go_loose(release_velocity)
	track_loose_body(body)
	# Drop the handle so finalisation does not free the loose body.
	_held_body = null


## Public seam so subsystems that spawn their own loose bodies (Shop) can wire re-grab through this controller.
func track_loose_body(body: HeldBody) -> void:
	if not body.pressed.is_connected(_on_loose_body_pressed):
		body.pressed.connect(_on_loose_body_pressed)


## Returns true if a release at `world_position` would be accepted by the court drop target.
func can_court_accept_at(item_key: String, world_position: Vector2) -> bool:
	for target: DropTarget in _drop_targets:
		if target is CourtDropTarget:
			if target.can_accept(item_key, world_position, 1.0):
				return true
			return false
	return false


## Re-grabs a loose body the player pressed; reuses the same body so the gesture stays diegetic.
func _on_loose_body_pressed(body: HeldBody) -> void:
	if _held_body != null:
		return
	var item_key: String = body.item_key

	var spawn_position: Vector2 = body.global_position
	body.pressed.disconnect(_on_loose_body_pressed)
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
	var definition: ItemDefinition = _get_item_definition(item_key)
	_grab_target_scale = definition.token_scale if definition != null else Vector2.ONE
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
	body._enable_press_area(false)
	# Reparent to the controller so the lift ease and follow-cursor flow handle it like a fresh grab.
	if body.get_parent() != self:
		body.get_parent().remove_child(body)
		add_child(body)


func _finalise_loose_gesture(item_key: String, release_position: Vector2, over_court: bool) -> void:
	_reset_gesture_state()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(item_key, release_position, over_court)


func _loose_body_host() -> Node:
	if reconciler != null:
		var host: Node = reconciler.get_ball_host()
		if host != null:
			return host
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
	if _held_body == null:
		return
	var hovering: bool = _find_accepting_target(_held_key, world_position, 1.0) != null
	var definition: ItemDefinition = _get_item_definition(_held_key)
	var base_scale: Vector2 = definition.token_scale if definition != null else Vector2.ONE
	if hovering:
		_held_body.scale = base_scale * HOVER_SCALE_BUMP
		_held_body.modulate = HOVER_MODULATE
	else:
		_held_body.scale = base_scale
		_held_body.modulate = NEUTRAL_MODULATE


func _update_expansion_state(world_position: Vector2) -> void:
	if _held_body == null:
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


## Live-ball cancels deactivate the on-court placement so the rack regrows the at-rest token.
func _cancel_to_source() -> void:
	var item_key: String = _held_key
	var was_on_court: bool = _held_was_on_court
	var origin: StringName = _held_origin
	var release_position: Vector2 = (
		_held_body.global_position if _held_body != null else _press_position
	)

	if origin == &"live" and was_on_court:
		if _item_manager != null and _item_manager.is_on_court(item_key):
			_item_manager.deactivate(item_key)

	_finalise_gesture(item_key, release_position, false)


func _finalise_gesture(item_key: String, release_position: Vector2, over_court: bool) -> void:
	if _held_body != null:
		_held_body.queue_free()
	_reset_gesture_state()
	_set_cursor_state(CursorStateScript.State.DEFAULT, release_position)
	drop_completed.emit(item_key, release_position, over_court)


func _reset_gesture_state() -> void:
	_held_body = null
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
	_set_court_exclude_rids([])


func _set_court_exclude_rids(rids: Array[RID]) -> void:
	for target: DropTarget in _drop_targets:
		if target is CourtDropTarget:
			(target as CourtDropTarget).set_exclude_rids(rids)


func _spawn_held_body(item_key: String, spawn_position: Vector2, is_temporary: bool) -> void:
	var definition: ItemDefinition = _get_item_definition(item_key)
	var target_scale: Vector2 = Vector2.ONE
	if definition != null:
		target_scale = definition.token_scale

	var body: HeldBody = HeldBody.make_for(definition, item_key)
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


## Priority order: court strict projection first, role-aware racks, venue catch-all last.
func _register_builtin_targets() -> void:
	_drop_targets.clear()
	_builtin_targets.clear()

	for target: DropTarget in [
		_make_court_target(),
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
	if _held_body == null:
		return
	# Cubic ease-out: 1 - (1 - t)^3.
	var inv: float = 1.0 - progress
	var eased: float = 1.0 - inv * inv * inv
	_held_body.global_position = _grab_origin_position.lerp(cursor_target, eased)
	_held_body.scale = (grab_ease_start_scale * _grab_target_scale).lerp(_grab_target_scale, eased)
	_held_body.modulate = grab_ease_start_modulate.lerp(grab_ease_end_modulate, eased)
	if progress >= 1.0 and _held_body.phase == HeldBody.Phase.LIFTING:
		_held_body.mark_held()


func _update_cursor_state(world_position: Vector2) -> void:
	var state: int = _derive_cursor_state(world_position)
	_set_cursor_state(state, world_position)


func _derive_cursor_state(world_position: Vector2) -> int:
	if _held_body == null:
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
	ball.pressed.connect(_on_live_ball_pressed.bind(item_key))


func _on_live_ball_pressed(_ball: Ball, item_key: String) -> void:
	grab_live_ball(item_key, false)


func _on_pickup_started(item_key: String) -> void:
	if rack != null:
		rack.hide_slot_for(item_key)
	if gear_rack != null:
		gear_rack.hide_slot_for(item_key)


func _on_drop_completed(item_key: String, _release_position: Vector2, _over_court: bool) -> void:
	if rack != null:
		rack.reveal_slot_for(item_key)
	if gear_rack != null:
		gear_rack.reveal_slot_for(item_key)
