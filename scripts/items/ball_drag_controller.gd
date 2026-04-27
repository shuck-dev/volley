class_name BallDragController
extends Node2D

## Owns the held-token visual during a ball or equipment drag gesture.
##
## Press starts a hold (held token follows cursor); release commits only at a valid target.
## No-restore principle (SH-287): mouse-up over an invalid spot does not end the gesture;
## the held token keeps following the cursor and the controller polls per frame for a valid
## target. The source rack is itself a target, giving the player a no-teleport escape valve.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, release_position: Vector2, over_court: bool)

const CURSOR_SAMPLE_WINDOW: float = 0.08
## Minimum cursor travel before a rack-origin gesture counts as a real drag (SH-252 a).
const COMMIT_MOVEMENT_THRESHOLD_PX: float = 6.0
## SH-287 patch: probe radius for the pre-spawn body projection; slightly larger than authored ball radius.
const COURT_BLOCKED_PROBE_RADIUS_PX: float = 14.0

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var gear_rack: RackDisplay
@export var gear_rack_drop_target: Area2D
@export var court_bounds: Rect2 = Rect2()
@export var venue_bounds: Rect2 = Rect2()
@export var reconciler: BallReconciler

var _item_manager: Node
var _held_token: Node2D = null
var _held_key: String = ""
var _held_is_temporary: bool = false
## Was the item on-court before the gesture? Rack pickups defer activation, so a click-without-movement is a no-op.
var _held_was_on_court: bool = false
var _cursor_samples: Array = []
## Cursor position when the held token spawned; gates the SH-252 a click-without-movement no-op.
var _press_position: Vector2 = Vector2.ZERO
var _gesture_below_threshold: bool = true
## SH-287: tracks mouse-button state so _process can poll for valid targets when mouse is up.
var _mouse_button_down: bool = false


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

	if rack != null and not rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		rack.slot_pressed.connect(_on_rack_slot_pressed)

	if gear_rack != null and not gear_rack.slot_pressed.is_connected(_on_rack_slot_pressed):
		gear_rack.slot_pressed.connect(_on_rack_slot_pressed)

	if reconciler != null:
		if not reconciler.ball_spawned.is_connected(_on_reconciler_ball_spawned):
			reconciler.ball_spawned.connect(_on_reconciler_ball_spawned)


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
	if not _mouse_button_down:
		attempt_release(follow_position)


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
	attempt_release(_clamp_to_venue(_event_world_position(mouse_button)))


func is_dragging() -> bool:
	return _held_token != null


func get_held_key() -> String:
	return _held_key


func get_held_token() -> Node2D:
	return _held_token


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
		if reconciler != null:
			reconciler.release_ball(item_key)
		existing.freeze = true
		existing.call_deferred("queue_free")

	_spawn_held_token(item_key, spawn_position, is_temporary)
	_held_was_on_court = not is_temporary
	_mouse_button_down = true
	pickup_started.emit(item_key)
	return true


## Try to commit the held gesture at the given position. Returns true on commit (held token freed,
## gesture ends), false on no valid target (held token stays, gesture continues).
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var clamped_position: Vector2 = _clamp_to_venue(release_position)
	var item_key: String = _held_key
	var item_role: StringName = _get_item_role(item_key)
	var over_rack_for_role: bool = _position_over_rack_for_role(clamped_position, item_role)

	# Direct callers bypass _process, so re-check distance here to keep the no-op gate honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			clamped_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)
	var was_temporary: bool = _held_is_temporary
	var was_on_court: bool = _held_was_on_court

	# SH-252 a: a press-and-release without movement on a rack-origin gesture cancels back to source.
	if below_threshold and not was_on_court and not was_temporary:
		_finalise_gesture(item_key, clamped_position, false)
		return true

	if over_rack_for_role:
		if not was_temporary and was_on_court and _item_manager.is_on_court(item_key):
			_item_manager.deactivate(item_key)
		_finalise_gesture(item_key, clamped_position, false)
		return true

	# Court target only accepts ball-role items at a position clear of other bodies.
	if item_role == &"ball":
		var court_position: Vector2 = _clamp_to_court(clamped_position)
		if _release_position_clear(court_position):
			var release_velocity: Vector2 = _compute_release_velocity()
			_release_onto_court(item_key, court_position, release_velocity, was_temporary)
			_finalise_gesture(item_key, clamped_position, true)
			return true

	# No valid target. Held token stays following the cursor; gesture continues.
	return false


func _release_onto_court(
	item_key: String,
	release_position: Vector2,
	release_velocity: Vector2,
	is_temporary: bool,
) -> void:
	if is_temporary:
		return
	if reconciler == null:
		return
	reconciler.bring_into_play(item_key, release_position, release_velocity)


## Clear held-token state after a successful commit (rack accept or court spawn).
func _finalise_gesture(item_key: String, release_position: Vector2, over_court: bool) -> void:
	if _held_token != null:
		_held_token.queue_free()
	_held_token = null
	_held_key = ""
	_held_is_temporary = false
	_held_was_on_court = false
	_cursor_samples.clear()
	_press_position = Vector2.ZERO
	_gesture_below_threshold = true
	drop_completed.emit(item_key, release_position, over_court)


## SH-287 patch: pre-spawn body projection. Returns true if a ball-sized circle at the position would not overlap any physics body.
func _release_position_clear(candidate_position: Vector2) -> bool:
	var world: World2D = get_world_2d()
	if world == null:
		return true
	var space: PhysicsDirectSpaceState2D = world.direct_space_state
	if space == null:
		return true
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = COURT_BLOCKED_PROBE_RADIUS_PX
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, candidate_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hits: Array = space.intersect_shape(params, 1)
	return hits.is_empty()


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
	_cursor_samples.clear()
	_track_cursor_motion(spawn_position)


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


## Returns true if the position is over a rack whose role accepts the held item's role.
func _position_over_rack_for_role(world_position: Vector2, item_role: StringName) -> bool:
	if item_role == &"ball" and _position_over_area(world_position, rack_drop_target):
		return true
	if item_role != &"ball" and _position_over_area(world_position, gear_rack_drop_target):
		return true
	return false


func _position_over_area(world_position: Vector2, area: Area2D) -> bool:
	if area == null:
		return false
	var shape_owner: CollisionShape2D = _first_collision_shape(area)
	if shape_owner == null:
		return false
	var rect: Rect2 = _world_rect_for_shape(area, shape_owner)
	return rect.has_point(world_position)


func _clamp_to_court(world_position: Vector2) -> Vector2:
	return _clamp_to_rect(world_position, court_bounds)


func _clamp_to_venue(world_position: Vector2) -> Vector2:
	return _clamp_to_rect(world_position, venue_bounds)


func _clamp_to_rect(world_position: Vector2, bounds: Rect2) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return world_position
	return Vector2(
		clampf(world_position.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clampf(world_position.y, bounds.position.y, bounds.position.y + bounds.size.y),
	)


func _first_collision_shape(area: Area2D) -> CollisionShape2D:
	for child in area.get_children():
		if child is CollisionShape2D:
			return child
	return null


func _world_rect_for_shape(area: Area2D, shape_node: CollisionShape2D) -> Rect2:
	var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rectangle == null:
		return Rect2()
	var half_extents: Vector2 = rectangle.size * 0.5
	var center: Vector2 = area.global_position + shape_node.position
	return Rect2(center - half_extents, rectangle.size)


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null


func _get_item_role(item_key: String) -> StringName:
	var definition: ItemDefinition = _get_item_definition(item_key)
	if definition == null:
		return &"ball"
	return definition.role


func _on_rack_slot_pressed(item_key: String, press_position: Vector2) -> void:
	grab_from_rack(item_key, press_position)


func _on_reconciler_ball_spawned(item_key: String, ball: Ball) -> void:
	# Each Ball is a fresh instance from ensure_ball_for_key, no double-connect risk.
	ball.pressed.connect(_on_live_ball_pressed.bind(item_key))


func _on_live_ball_pressed(_ball: Ball, item_key: String) -> void:
	grab_live_ball(item_key, false)
