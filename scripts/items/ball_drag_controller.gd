class_name BallDragController
extends Node2D

## Owns the held-token visual during a ball drag gesture.
## Rack click or live-ball click spawns a held token; release over court instates a Ball,
## release over rack destroys the token and the rack refresh regrows the rack token.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, position: Vector2, over_court: bool)

const GESTURE_SAMPLE_WINDOW: float = 0.08

@export var rack: RackDisplay
@export var rack_drop_target: Area2D
@export var court_bounds: Rect2 = Rect2()
@export var reconciler: BallReconciler

var _item_manager: Node
var _held_token: Node2D = null
var _held_key: String = ""
var _held_is_temporary: bool = false
var _held_from_rack: bool = true
var _gesture_samples: Array = []


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


func _process(_delta: float) -> void:
	if _held_token == null:
		return
	_held_token.global_position = _cursor_position()
	_sample_gesture(_held_token.global_position)


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
	attempt_release(_cursor_position())


func is_dragging() -> bool:
	return _held_token != null


func get_held_key() -> String:
	return _held_key


func get_held_token() -> Node2D:
	return _held_token


## Test seam / production entry for rack-origin pickups.
func grab_from_rack(item_key: String) -> bool:
	if _held_token != null:
		return false
	if _item_manager.get_level(item_key) <= 0:
		return false
	if _item_manager.is_on_court(item_key):
		return false
	_spawn_held_token(item_key, _cursor_position(), false)
	_held_from_rack = true
	_item_manager.activate(item_key)
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
		existing.call_deferred("queue_free")
	_spawn_held_token(item_key, spawn_position, is_temporary)
	_held_from_rack = false
	pickup_started.emit(item_key)
	return true


## Release the held token at the given position. Fires only over rack or court;
## outside either zone the hold continues.
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false
	var over_rack: bool = _position_over_rack(release_position)
	var over_court: bool = _position_over_court(release_position)
	if not over_rack and not over_court:
		return false
	var item_key: String = _held_key
	var token: Node2D = _held_token
	var was_temporary: bool = _held_is_temporary
	var gesture_velocity: Vector2 = _compute_gesture_velocity()
	_held_token = null
	_held_key = ""
	_held_is_temporary = false
	_gesture_samples.clear()
	token.queue_free()
	if over_rack:
		if not was_temporary and _item_manager.is_on_court(item_key):
			_item_manager.deactivate(item_key)
	else:
		_release_onto_court(
			item_key, _clamp_to_court(release_position), gesture_velocity, was_temporary
		)
	drop_completed.emit(item_key, release_position, over_court and not over_rack)
	return true


func _release_onto_court(
	item_key: String,
	release_position: Vector2,
	gesture_velocity: Vector2,
	is_temporary: bool,
) -> void:
	if is_temporary:
		return
	if not _item_manager.is_on_court(item_key):
		_item_manager.activate(item_key)
	if reconciler != null:
		reconciler.spawn_for_key(item_key, release_position, gesture_velocity)


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
	_gesture_samples.clear()
	_sample_gesture(spawn_position)


func _sample_gesture(sample_position: Vector2) -> void:
	var now_ms: float = float(Time.get_ticks_msec()) / 1000.0
	_gesture_samples.append({"time": now_ms, "position": sample_position})
	while _gesture_samples.size() > 1:
		var oldest: Dictionary = _gesture_samples[0]
		if now_ms - float(oldest["time"]) > GESTURE_SAMPLE_WINDOW:
			_gesture_samples.remove_at(0)
		else:
			break


func _compute_gesture_velocity() -> Vector2:
	if _gesture_samples.size() < 2:
		return _default_release_velocity()
	var first: Dictionary = _gesture_samples[0]
	var last: Dictionary = _gesture_samples[_gesture_samples.size() - 1]
	var time_delta: float = float(last["time"]) - float(first["time"])
	if time_delta <= 0.0:
		return _default_release_velocity()
	var pos_delta: Vector2 = Vector2(last["position"]) - Vector2(first["position"])
	var velocity: Vector2 = pos_delta / time_delta
	if velocity.length() < 1.0:
		return _default_release_velocity()
	return velocity


func _default_release_velocity() -> Vector2:
	var min_speed: float = _item_manager.get_stat(&"ball_speed_min")
	return Vector2(min_speed, min_speed * 0.5).normalized() * min_speed


func _cursor_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return global_position
	return viewport.get_mouse_position()


func _position_over_rack(position: Vector2) -> bool:
	if rack_drop_target == null:
		return false
	var shape_owner: CollisionShape2D = _first_collision_shape(rack_drop_target)
	if shape_owner == null:
		return false
	var rect: Rect2 = _world_rect_for_shape(rack_drop_target, shape_owner)
	return rect.has_point(position)


func _position_over_court(position: Vector2) -> bool:
	if court_bounds.size == Vector2.ZERO:
		return not _position_over_rack(position)
	return court_bounds.has_point(position)


func _clamp_to_court(position: Vector2) -> Vector2:
	if court_bounds.size == Vector2.ZERO:
		return position
	var clamped := Vector2(
		clampf(position.x, court_bounds.position.x, court_bounds.position.x + court_bounds.size.x),
		clampf(position.y, court_bounds.position.y, court_bounds.position.y + court_bounds.size.y),
	)
	return clamped


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


func _on_rack_slot_pressed(item_key: String) -> void:
	grab_from_rack(item_key)
