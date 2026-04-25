class_name BallDragController
extends Node2D

## Owns the held-token visual during a ball drag gesture.
##
## Press starts a hold (held token follows cursor); release decides the outcome.
## Rack press: held token spawns, item stays inactive until release over court.
## Live-ball press: live Ball is freed, held token takes over until release.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, position: Vector2, over_court: bool)

const CURSOR_SAMPLE_WINDOW: float = 0.08
## Minimum cursor travel before a rack-origin gesture is treated as a real drag.
## Below this, press-release at the same spot is a click-without-movement no-op (SH-252 a).
const COMMIT_MOVEMENT_THRESHOLD_PX: float = 6.0

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
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
## Cursor position when the held token spawned. Used to decide whether the gesture moved
## far enough to count as a real drag (SH-252 a click-without-movement no-op).
var _press_position: Vector2 = Vector2.ZERO
## True until the cursor has travelled past COMMIT_MOVEMENT_THRESHOLD_PX from `_press_position`.
var _gesture_below_threshold: bool = true


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


func _input(event: InputEvent) -> void:
	if _held_token == null:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_button.pressed:
		return

	# Use the event's own position (mapped through the canvas transform) so the release
	# point is the player's actual cursor at mouse-up, not whatever the viewport's stale
	# mouse state is. This is what makes a Camera2D in the venue not break rack hit-testing.
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
		existing.set_dragging(true)
		existing.call_deferred("queue_free")

	_spawn_held_token(item_key, spawn_position, is_temporary)
	_held_was_on_court = not is_temporary
	pickup_started.emit(item_key)
	return true


## Release the held token; held-token follow already clamps cursor to venue, so release always resolves.
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var clamped_position: Vector2 = _clamp_to_venue(release_position)
	var over_rack: bool = _position_over_rack(clamped_position)
	# Cursor follow runs in _process; for direct callers (tests, deferred release), also
	# check the release position against the press position so the no-op gate stays honest.
	var below_threshold: bool = _gesture_below_threshold
	if below_threshold:
		below_threshold = (
			clamped_position.distance_to(_press_position) < COMMIT_MOVEMENT_THRESHOLD_PX
		)

	var item_key: String = _held_key
	var token: Node2D = _held_token
	var was_temporary: bool = _held_is_temporary
	var was_on_court: bool = _held_was_on_court
	var release_velocity: Vector2 = _compute_release_velocity()

	_held_token = null
	_held_key = ""
	_held_is_temporary = false
	_held_was_on_court = false
	_cursor_samples.clear()
	_press_position = Vector2.ZERO
	_gesture_below_threshold = true
	token.queue_free()

	# SH-252 a: a press-release without real cursor movement on a rack-origin pickup is a
	# click, not a drag. Held token lifts on press, but we cancel back to the rack rather
	# than committing the ball to the court.
	var click_without_movement: bool = below_threshold and not was_on_court and not was_temporary
	if click_without_movement:
		drop_completed.emit(item_key, clamped_position, false)
		return true

	if over_rack:
		# Rack release returns the item to inactive storage; if it had been on court before
		# the gesture, deactivate. Rack pickups that started inactive stay inactive.
		if not was_temporary and was_on_court and _item_manager.is_on_court(item_key):
			_item_manager.deactivate(item_key)
	else:
		_release_onto_court(
			item_key, _clamp_to_court(clamped_position), release_velocity, was_temporary
		)

	drop_completed.emit(item_key, clamped_position, not over_rack)
	return true


func _release_onto_court(
	item_key: String,
	release_position: Vector2,
	release_velocity: Vector2,
	is_temporary: bool,
) -> void:
	if is_temporary:
		return

	# Activation happens at release-over-court so a click without movement on the rack
	# does not introduce the ball (SH-245).
	if not _item_manager.is_on_court(item_key):
		_item_manager.activate(item_key)

	if reconciler != null:
		reconciler.ensure_ball_for_key(item_key, release_position, release_velocity)


func _spawn_held_token(item_key: String, spawn_position: Vector2, is_temporary: bool) -> void:
	var token: Node2D = Node2D.new()
	token.name = "HeldToken_%s" % item_key
	token.global_position = spawn_position

	var definition: ItemDefinition = _get_item_definition(item_key)
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
	# Use the canvas-aware global mouse position so a Camera2D in the venue does not
	# decouple the held token's follow position from the world rect tests for rack /
	# court hit-testing (SH-252 b regression: viewport-local coords missed the rack).
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return global_position
	return get_global_mouse_position()


## Maps a mouse button event's viewport-local position into world coordinates so canvas
## transforms (Camera2D) do not break rack/court hit-testing on release.
func _event_world_position(event: InputEventMouseButton) -> Vector2:
	var canvas_transform: Transform2D = get_canvas_transform()
	return canvas_transform.affine_inverse() * event.position


func _position_over_rack(position: Vector2) -> bool:
	if rack_drop_target == null:
		return false

	var shape_owner: CollisionShape2D = _first_collision_shape(rack_drop_target)
	if shape_owner == null:
		return false

	var rect: Rect2 = _world_rect_for_shape(rack_drop_target, shape_owner)
	return rect.has_point(position)


func _clamp_to_court(position: Vector2) -> Vector2:
	return _clamp_to_rect(position, court_bounds)


func _clamp_to_venue(position: Vector2) -> Vector2:
	return _clamp_to_rect(position, venue_bounds)


func _clamp_to_rect(position: Vector2, bounds: Rect2) -> Vector2:
	if bounds.size == Vector2.ZERO:
		return position
	return Vector2(
		clampf(position.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clampf(position.y, bounds.position.y, bounds.position.y + bounds.size.y),
	)


func _first_collision_shape(area: Area2D) -> CollisionShape2D:
	for child in area.get_children():
		if child is CollisionShape2D:
			return child
	return null


func _world_rect_for_shape(area: Area2D, shape_node: CollisionShape2D) -> Rect2:
	var shape: Shape2D = shape_node.shape
	if not (shape is RectangleShape2D):
		return Rect2()

	var rectangle: RectangleShape2D = shape
	var half_size: Vector2 = rectangle.size * 0.5
	var center: Vector2 = area.global_position + shape_node.position
	return Rect2(center - half_size, rectangle.size)


func _get_item_definition(item_key: String) -> ItemDefinition:
	for item: ItemDefinition in _item_manager.items:
		if item.key == item_key:
			return item
	return null


func _on_rack_slot_pressed(item_key: String, press_position: Vector2) -> void:
	grab_from_rack(item_key, press_position)


func _on_reconciler_ball_spawned(item_key: String, ball: Ball) -> void:
	# Each Ball is a fresh instance from ensure_ball_for_key, no double-connect risk.
	ball.pressed.connect(_on_live_ball_pressed.bind(item_key))


func _on_live_ball_pressed(_ball: Ball, item_key: String) -> void:
	grab_live_ball(item_key, false)
