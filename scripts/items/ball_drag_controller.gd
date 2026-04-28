class_name BallDragController
extends Node2D

## Owns the held-token visual during a ball or equipment drag gesture and polls every registered DropTarget for a valid commit.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, release_position: Vector2, over_court: bool)

const CURSOR_SAMPLE_WINDOW: float = 0.08
const PRESERVED_SPEED_NONE: float = -1.0
## Minimum cursor travel before a rack-origin gesture counts as a real drag (SH-252 a).
const COMMIT_MOVEMENT_THRESHOLD_PX: float = 6.0
const HOVER_SCALE_BUMP: Vector2 = Vector2(1.08, 1.08)
const HOVER_MODULATE: Color = Color(1.15, 1.15, 1.15, 1.0)
const NEUTRAL_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var gear_rack: RackDisplay
@export var gear_rack_drop_target: Area2D
@export var court_bounds: Rect2 = Rect2()
@export var venue_bounds: Rect2 = Rect2()
@export var reconciler: BallReconciler
@export var expansion_ring_hold_s: float = 0.25
@export var expansion_ring_scale: float = 1.5

var _item_manager: Node
var _held_token: Node2D = null
var _held_key: String = ""
var _held_is_temporary: bool = false
## Was the item on-court before the gesture? Rack pickups defer activation, so a click-without-movement is a no-op.
var _held_was_on_court: bool = false
## Origin tag for the current gesture: &"rack" (default), &"live" (mid-rally grab).
## Drives the SH-252 click-without-movement no-op gate (rack-only) and future hooks.
var _held_origin: StringName = &"rack"
var _cursor_samples: Array = []
## Cursor position when the held token spawned; gates the SH-252 a click-without-movement no-op.
var _press_position: Vector2 = Vector2.ZERO
var _gesture_below_threshold: bool = true
## SH-287: tracks mouse-button state so _process can poll for valid targets when mouse is up.
var _mouse_button_down: bool = false
## SH-288: friendship energy captured at mid-rally grab; forwarded to bring_into_play so the
## released ball inherits the rally speed. Negative means no preserved energy.
var _held_preserved_speed: float = PRESERVED_SPEED_NONE
## SH-287: monotonic time in seconds when the controller began trying expansion-ring polling
## (i.e. mouse-up with strict projection failing). Negative means not yet timing.
var _expansion_started_at: float = -1.0

var _drop_targets: Array[DropTarget] = []
## Targets the controller authored from its own exports; rebuilt on `_ready` and not
## removed by the public `unregister_target` API.
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

	# Group lookup so Shop (and any future origin) can hand presses to the controller
	# without an explicit NodePath in court.tscn.
	add_to_group(&"drag_controller")

	if rack != null and not rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		rack.slot_pressed.connect(_on_rack_slot_pressed)

	if gear_rack != null and not gear_rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		gear_rack.slot_pressed.connect(_on_rack_slot_pressed)

	if reconciler != null:
		if not reconciler.ball_spawned.is_connected(_on_reconciler_ball_spawned):
			reconciler.ball_spawned.connect(_on_reconciler_ball_spawned)

	_register_builtin_targets()


func _process(_delta: float) -> void:
	if _held_token == null:
		return

	var follow_position: Vector2 = _clamp_to_venue(_cursor_position())
	_held_token.global_position = follow_position
	_track_cursor_motion(follow_position)
	if _gesture_below_threshold:
		if follow_position.distance_to(_press_position) >= COMMIT_MOVEMENT_THRESHOLD_PX:
			_gesture_below_threshold = false

	# SH-287: when mouse is up and the held position is over a valid target, commit.
	# Otherwise keep the held token following the cursor and update hover feedback.
	if not _mouse_button_down:
		if not attempt_release(follow_position):
			_update_expansion_state(follow_position)
	else:
		_update_hover_feedback(follow_position)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return

	_mouse_button_down = mouse_button.pressed
	if mouse_button.pressed or _held_token == null:
		return

	# Use the event's own position so a Camera2D in the venue doesn't break rack hit-testing.
	if not attempt_release(_clamp_to_venue(_event_world_position(mouse_button))):
		_expansion_started_at = _now_seconds()


func is_dragging() -> bool:
	return _held_token != null


func get_held_key() -> String:
	return _held_key


func get_held_token() -> Node2D:
	return _held_token


## Public registration so subsystems with their own area resources (Shop) can join the
## target poll without owning the held token.
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


## Test seam / production entry for rack-origin pickups. Activation defers to release-over-court (SH-245).
func grab_from_rack(item_key: String, press_position: Variant = null) -> bool:
	if _held_token != null:
		return false
	if _item_manager.get_level(item_key) <= 0:
		return false
	if _item_manager.is_on_court(item_key):
		return false

	var spawn_position: Vector2 = (
		press_position if press_position is Vector2 else _cursor_position()
	)
	_spawn_held_token(item_key, spawn_position, false)
	_held_was_on_court = false
	_held_origin = &"rack"
	# A grab only happens on a press; assume mouse is down so polling waits for mouse-up.
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


## Test seam / production entry for mid-rally live-ball grabs.
func grab_live_ball(item_key: String, is_temporary: bool = false) -> bool:
	if _held_token != null:
		return false

	var existing: Ball = null
	if reconciler != null:
		existing = reconciler.get_ball_for_key(item_key)

	var spawn_position: Vector2 = _cursor_position()
	if existing != null:
		spawn_position = existing.global_position
		# SH-288: capture the rally's friendship energy before freeing the live ball so the
		# released ball inherits it. Reset only on miss, never on grab-and-release.
		_held_preserved_speed = existing.speed
		if reconciler != null:
			reconciler.release_ball(item_key)
		existing.freeze = true
		existing.call_deferred("queue_free")

	_spawn_held_token(item_key, spawn_position, is_temporary)
	_held_was_on_court = not is_temporary
	_held_origin = &"live"
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


## Shop-purchase entry: returns true if a court/venue target accepted; false routes the new token to the rack.
func spawn_purchased_at(
	item_key: String, world_position: Vector2, gesture_velocity: Vector2
) -> bool:
	# No venue clamp: a release outside the venue should fall through to the rack.
	var target: DropTarget = _find_accepting_target(item_key, world_position, 1.0)
	if target == null:
		return false
	if not (target is CourtDropTarget or target is VenueDropTarget):
		return false
	target.accept(item_key, world_position, gesture_velocity)
	return true


## Try to commit the held gesture at the given position. Returns true on commit (held token
## freed, gesture ends), false on no valid target (held token stays, gesture continues).
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var clamped_position: Vector2 = _clamp_to_venue(release_position)
	var item_key: String = _held_key
	var was_temporary: bool = _held_is_temporary

	# Direct callers bypass _process, so re-check distance here to keep the no-op gate honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			clamped_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)

	# SH-252 a: a press-and-release without movement on a rack-origin gesture cancels back to source.
	if below_threshold and _held_origin == &"rack" and not _held_was_on_court and not was_temporary:
		_finalise_gesture(item_key, clamped_position, false)
		return true

	# Strict pass first; on miss the caller (process loop) decides whether to start the
	# expansion-ring timer.
	var target: DropTarget = _find_accepting_target(item_key, clamped_position, 1.0)
	if target == null and _expansion_started_at >= 0.0:
		var held_duration: float = _now_seconds() - _expansion_started_at
		if held_duration >= expansion_ring_hold_s:
			target = _find_accepting_target(item_key, clamped_position, expansion_ring_scale)

	if target == null:
		return false

	if target is CourtDropTarget or target is VenueDropTarget:
		var velocity: Vector2 = _compute_release_velocity()
		if was_temporary:
			# Temporary balls bypass the reconciler so they don't survive the gesture.
			pass
		else:
			target.accept(item_key, clamped_position, velocity)
			_apply_preserved_speed_after_accept(item_key)
	else:
		target.accept(item_key, clamped_position, Vector2.ZERO)

	var over_court: bool = target is CourtDropTarget or target is VenueDropTarget
	if was_temporary:
		over_court = false
	_finalise_gesture(item_key, clamped_position, over_court)
	return true


## Re-applies mid-rally preserved speed to the freshly spawned ball after a court/venue accept.
func _apply_preserved_speed_after_accept(item_key: String) -> void:
	if _held_preserved_speed < 0.0:
		return
	if reconciler == null:
		return
	var ball: Ball = reconciler.get_ball_for_key(item_key)
	if ball == null:
		return
	ball.speed = _held_preserved_speed
	if ball.linear_velocity.length() > 0.0:
		ball.linear_velocity = ball.linear_velocity.normalized() * _held_preserved_speed


## Returns the first registered target whose `can_accept` succeeds, or null. Targets are
## polled in registration order; built-ins register in priority order (court before venue).
func _find_accepting_target(
	item_key: String, world_position: Vector2, scale_factor: float
) -> DropTarget:
	for target: DropTarget in _drop_targets:
		if target.can_accept(item_key, world_position, scale_factor):
			return target
	return null


## Hover-feedback bump applied to the held token while a target accepts the current pos.
func _update_hover_feedback(world_position: Vector2) -> void:
	if _held_token == null:
		return
	var hovering: bool = _find_accepting_target(_held_key, world_position, 1.0) != null
	var definition: ItemDefinition = _get_item_definition(_held_key)
	var base_scale: Vector2 = definition.token_scale if definition != null else Vector2.ONE
	if hovering:
		_held_token.scale = base_scale * HOVER_SCALE_BUMP
		_held_token.modulate = HOVER_MODULATE
	else:
		_held_token.scale = base_scale
		_held_token.modulate = NEUTRAL_MODULATE


## After mouse-up: maintain the expansion-ring timer. Cancels back to source if the
## widened poll has also failed for the same hold window.
func _update_expansion_state(world_position: Vector2) -> void:
	if _held_token == null:
		return
	if _expansion_started_at < 0.0:
		_expansion_started_at = _now_seconds()
		return

	var held_duration: float = _now_seconds() - _expansion_started_at
	if held_duration < expansion_ring_hold_s:
		return

	# Strict pass already ran in attempt_release; try the widened pass now. If it succeeds,
	# attempt_release picks it up next frame. If the widened pass has also been failing for
	# another full hold window, cancel back to source.
	var widened: DropTarget = _find_accepting_target(
		_held_key, world_position, expansion_ring_scale
	)
	if widened != null:
		# attempt_release on the next frame will use the widened scale because the timer
		# crossed the threshold; re-running it now lets us commit immediately.
		attempt_release(world_position)
		return

	if held_duration >= expansion_ring_hold_s * 2.0:
		_cancel_to_source()


## Two-window expansion fail -> cancel-to-source. Free the held token; deactivate any
## on-court placement that a live-ball grab would have moved so the rack regrows it.
func _cancel_to_source() -> void:
	var item_key: String = _held_key
	var was_on_court: bool = _held_was_on_court
	var origin: StringName = _held_origin
	var release_position: Vector2 = (
		_held_token.global_position if _held_token != null else _press_position
	)

	if origin == &"live" and was_on_court:
		if _item_manager != null and _item_manager.is_on_court(item_key):
			_item_manager.deactivate(item_key)

	_finalise_gesture(item_key, release_position, false)


## Clear held-token state after a successful commit (rack accept or court spawn).
func _finalise_gesture(item_key: String, release_position: Vector2, over_court: bool) -> void:
	if _held_token != null:
		_held_token.queue_free()
	_held_token = null
	_held_key = ""
	_held_is_temporary = false
	_held_was_on_court = false
	_held_origin = &"rack"
	_held_preserved_speed = PRESERVED_SPEED_NONE
	_cursor_samples.clear()
	_press_position = Vector2.ZERO
	_gesture_below_threshold = true
	_expansion_started_at = -1.0
	drop_completed.emit(item_key, release_position, over_court)


func _spawn_held_token(item_key: String, spawn_position: Vector2, is_temporary: bool) -> void:
	var token: Node2D = Node2D.new()
	token.name = "HeldToken_%s" % item_key
	token.global_position = spawn_position

	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition != null:
		token.scale = definition.token_scale
	if definition != null and definition.art != null:
		var art_instance: Node = definition.art.instantiate()
		token.add_child(art_instance)
	add_child(token)

	_held_token = token
	_held_key = item_key
	_held_is_temporary = is_temporary
	_press_position = spawn_position
	_gesture_below_threshold = true
	_expansion_started_at = -1.0
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)


## Registers the controller's authored targets in priority order: court strict projection first, role-aware racks, venue catch-all.
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
	return venue_target


## Records cursor positions across a short rolling window so release velocity can be derived from recent motion.
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


func _on_rack_slot_pressed(item_key: String, press_position: Vector2) -> void:
	grab_from_rack(item_key, press_position)


func _on_reconciler_ball_spawned(item_key: String, ball: Ball) -> void:
	# Each Ball is a fresh instance from ensure_ball_for_key, no double-connect risk.
	ball.pressed.connect(_on_live_ball_pressed.bind(item_key))


func _on_live_ball_pressed(_ball: Ball, item_key: String) -> void:
	grab_live_ball(item_key, false)
