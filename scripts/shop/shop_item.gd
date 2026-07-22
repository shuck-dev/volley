class_name ShopItem
extends Node2D

## Diegetic shop item; the drag IS the buy gesture, release outside shop commits.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, position: Vector2, purchased: bool)

@export var art_holder: Node2D
@export var pickup_area: Area2D
@export var case_overlay: Node2D
@export var tuning: ShopDragTuning

var item_definition: ItemDefinition

var _item_manager: ItemManager
var _art_instance: ItemArt
var _shop_area: Area2D
var _held_token: Node2D = null
var _last_input_frame: int = -1
## SH-287: tracks mouse-button state so _process can poll for valid targets when mouse is up.
var _mouse_button_down: bool = false
## Cursor position when the gesture started; used to gate sub-threshold clicks from real drags.
var _press_position: Vector2 = Vector2.ZERO
## Maximum cursor travel seen during the gesture; out-and-back drags still spawn a body.
var _max_travel_seen: float = 0.0


func configure(item_manager: Node, definition: ItemDefinition) -> void:
	_item_manager = item_manager
	item_definition = definition
	_apply_token_scale()
	_build_art()
	_refresh_case_overlay()


## The Shop scene injects its own ShopArea so release detection can hit-test against it.
func bind_shop_area(area: Area2D) -> void:
	_shop_area = area


func can_be_owned() -> bool:
	if item_definition == null or _item_manager == null:
		return false
	return _item_manager.can_acquire(item_definition.key)


## Pickup permission: owned items stay draggable, unowned must be affordable.
func can_be_dragged() -> bool:
	if is_owned():
		return true
	return can_be_owned()


func is_owned() -> bool:
	if item_definition == null or _item_manager == null:
		return false
	return _item_manager.get_owned_count(item_definition.key) > 0


func is_dragging() -> bool:
	return _held_token != null


func get_held_token() -> Node2D:
	return _held_token


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if pickup_area != null and not pickup_area.input_event.is_connected(_on_input_event):
		pickup_area.input_event.connect(_on_input_event)
	_item_manager.soul_balance_changed.connect(_on_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_apply_token_scale()
	_refresh_case_overlay()


func _process(_delta: float) -> void:
	if _held_token == null:
		return
	var cursor: Vector2 = _cursor_position()
	_held_token.global_position = cursor
	var travel: float = cursor.distance_to(_press_position)
	if travel > _max_travel_seen:
		_max_travel_seen = travel
	# SH-287: when mouse is up, poll for a valid commit position so the gesture ends the moment one is reachable.
	if not _mouse_button_down:
		attempt_release(cursor)


# Release handled here so a fast drag that outruns the area still ends the drag.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	_mouse_button_down = mouse_button.pressed
	if mouse_button.pressed or _held_token == null:
		return
	# Use the event's own position so canvas transforms don't break the inside-shop hit-test.
	var canvas_transform: Transform2D = get_canvas_transform()
	var release_position: Vector2 = canvas_transform.affine_inverse() * mouse_button.position
	attempt_release(release_position)


func _build_art() -> void:
	if item_definition == null or item_definition.art == null:
		return
	if _art_instance != null and is_instance_valid(_art_instance):
		_art_instance.queue_free()
	_art_instance = item_definition.art.instantiate()
	art_holder.add_child(_art_instance)


func _apply_token_scale() -> void:
	if art_holder == null or item_definition == null:
		return
	art_holder.scale = item_definition.token_scale


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	_last_input_frame = Engine.get_physics_frames()
	if mouse_button.pressed and can_be_dragged() and _held_token == null:
		_start_drag()


func get_last_input_frame() -> int:
	return _last_input_frame


## Test seam / production entry. Begins the held-token gesture from the item's current spot.
func start_drag() -> bool:
	if _held_token != null:
		return false
	if not can_be_dragged():
		return false
	_start_drag()
	return true


## Release outcomes branch on inside-shop vs outside, plus travel-threshold for inside drags.
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var inside_shop: bool = _is_position_inside_shop(release_position)
	if not inside_shop:
		var purchase_key: String = _complete_purchase()
		if purchase_key == "" and not is_owned():
			return false
		var key: String = purchase_key if purchase_key != "" else _next_instance_key()
		var controller: Node = _drag_controller()
		var spawned: bool = false
		if controller != null and controller.has_method("spawn_purchased_at"):
			spawned = controller.spawn_purchased_at(key, release_position, _release_velocity())
		if not spawned:
			_drop_falling_body(release_position)
		_finalise_gesture(release_position, true)
		visible = false
		return true

	# Inside-shop branch.
	var threshold: float = tuning.drag_threshold_px if tuning != null else 2.0
	var release_travel: float = release_position.distance_to(_press_position)
	var gesture_travel: float = maxf(_max_travel_seen, release_travel)
	if gesture_travel < threshold:
		# Pure click: no body spawned, slot returns visible, no purchase.
		_finalise_gesture(release_position, false)
		visible = true
		return true

	# Real drag inside shop: spawn falling body; settle decides commit-vs-cancel.
	_drop_falling_body(release_position)
	_finalise_gesture(release_position, false)
	# Visibility flip waits on the settle decision; the body's settle watcher resolves it.
	return true


func _drag_controller() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"drag_controller")


## Drops a falling body for the inside-shop or fallthrough case; ball-role lands as a registry Ball
## in OUT_REST, equipment keeps the HeldBody loose path.
func _drop_falling_body(release_position: Vector2) -> void:
	if item_definition == null:
		return
	var controller: Node = _drag_controller()
	var clamped_position: Vector2 = _clamp_release_into_venue(release_position, controller)
	if _is_ball_role():
		_drop_ball_role(clamped_position, controller)
		return
	_drop_equipment_body(clamped_position, controller)


func _is_ball_role() -> bool:
	return item_definition != null and item_definition.role == &"ball"


func _clamp_release_into_venue(release_position: Vector2, controller: Node) -> Vector2:
	if controller == null or not ("venue_bounds" in controller):
		return release_position
	var bounds: Rect2 = controller.venue_bounds
	if bounds.size == Vector2.ZERO:
		return release_position
	return DropTarget.clamp_to_rect(release_position, bounds)


func _drop_equipment_body(clamped_position: Vector2, controller: Node) -> void:
	var body: HeldBody = HeldBody.make_for(item_definition, item_definition.key)
	if body == null:
		return
	var host: Node = _scene_host()
	if controller != null and controller.has_method("get_loose_body_host"):
		var resolved: Node = controller.get_loose_body_host()
		if resolved != null:
			host = resolved
	body.global_position = clamped_position
	host.add_child(body)
	body.go_loose(_release_velocity())
	if controller != null and controller.has_method("track_loose_body"):
		controller.track_loose_body(body)
	_watch_for_settle(body)


## Spawns the Ball directly in OUT_REST via the reconciler; if it settles inside-shop the Ball is
## torn down for refund, otherwise the purchase commits and the Ball stays in the registry.
func _drop_ball_role(clamped_position: Vector2, controller: Node) -> void:
	var reconciler: Node = _resolve_reconciler(controller)
	if reconciler == null:
		return
	var purchase_key: String = ItemManager.generate_instance_key(item_definition.key)
	var ball: Ball = reconciler.release_into_rest(
		purchase_key, clamped_position, _release_velocity()
	)
	if ball == null:
		return
	_watch_for_settle(ball)


func _resolve_reconciler(controller: Node) -> Node:
	if controller != null and "reconciler" in controller and controller.reconciler != null:
		return controller.reconciler
	return null


func _scene_host() -> Node:
	var current: Node = get_tree().current_scene
	if current != null:
		return current
	return get_tree().root


func _watch_for_settle(body: RigidBody2D) -> void:
	# Poll until the body's velocity falls below a settle threshold or it is freed.
	# Use load() so the class-name cache (which can be async-stale) doesn't mismatch path-based lookups.
	var drop: Node = load("res://scripts/shop/shop_item_drop.gd").new()
	drop.tuning = tuning
	drop.configure(body, self)
	body.add_child(drop)


## Called by ShopItemDrop with the body's resting position once velocity has settled.
func notify_body_settled(body: RigidBody2D, settled_position: Vector2) -> void:
	if item_definition == null:
		if is_instance_valid(body):
			body.queue_free()
		return
	if not is_instance_valid(body):
		return

	if body is Ball:
		_notify_ball_settled(body, settled_position)
		return

	if _is_position_inside_shop(settled_position):
		# Inside shop on rest: no purchase commits, slot returns.
		body.queue_free()
		visible = true
		return

	# Outside shop: re-check affordability at settle time. The player may have spent soul
	# elsewhere mid-flight; in that case free the body and restore the slot rather than leak it.
	if not is_owned():
		if not _complete_purchase():
			body.queue_free()
			visible = true
			return
	visible = false
	# Promote the body to a loose-in-venue overlay so the rack filter and re-grab paths treat it like any other loose body.
	var controller: Node = _drag_controller()
	if controller != null and controller.has_method("register_loose_body"):
		controller.register_loose_body(body)
	drop_completed.emit(item_definition.key, settled_position, true)


## Ball-role settle: registry-resident Ball is either kept (purchase commits) or released (refund).
func _notify_ball_settled(ball: Ball, settled_position: Vector2) -> void:
	var controller: Node = _drag_controller()
	var reconciler: Node = _resolve_reconciler(controller)

	if _is_position_inside_shop(settled_position):
		_release_ball_from_registry(reconciler, ball)
		visible = true
		return

	if not is_owned():
		if not _complete_purchase():
			_release_ball_from_registry(reconciler, ball)
			visible = true
			return

	visible = false
	ItemManager.mark_loose_in_venue(ball.item_key, settled_position)
	drop_completed.emit(ball.item_key, settled_position, true)


func _release_ball_from_registry(reconciler: Node, ball: Ball) -> void:
	if reconciler != null and reconciler.has_method("release_ball"):
		reconciler.release_ball(ball.item_key)
	if is_instance_valid(ball):
		ball.queue_free()


func _release_velocity() -> Vector2:
	return ItemManager.get_default_ball_launch_velocity()


func _finalise_gesture(release_position: Vector2, purchased: bool) -> void:
	if _held_token != null:
		_held_token.queue_free()
	_held_token = null
	drop_completed.emit(item_definition.key, release_position, purchased)


func _start_drag() -> void:
	var token: Node2D = Node2D.new()
	token.name = "HeldToken_%s" % item_definition.key
	if item_definition != null:
		token.scale = item_definition.token_scale
	if item_definition != null and item_definition.art != null:
		var art_instance: Node = item_definition.art.instantiate()
		token.add_child(art_instance)
	# Parent at scene root so the held visual follows the cursor without being
	# tied to the shop item's transform.
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		current_scene.add_child(token)
	else:
		add_child(token)
	var cursor: Vector2 = _cursor_position()
	token.global_position = cursor
	_held_token = token
	_press_position = cursor
	_max_travel_seen = 0.0
	# Hide the source slot during the drag so the player sees one item, not two (SH-251).
	visible = false
	_mouse_button_down = true
	pickup_started.emit(item_definition.key)


func _next_instance_key() -> String:
	if not _is_ball_role() or not is_owned():
		return item_definition.key
	for key in _item_manager.get_kit_items(&"ball"):
		if BallKey.is_instance(item_definition.key, key):
			return key
		return _item_manager.generate_instance_key(item_definition.key)
	return item_definition.key


func _complete_purchase() -> String:
	if not can_be_owned():
		return ""
	if _is_ball_role():
		if _item_manager.get_owned_count(item_definition.key) >= item_definition.max_level:
			return ""
	else:
		if is_owned():
			return ""
	var purchase_key: String = item_definition.key
	if _is_ball_role():
		purchase_key = ItemManager.generate_instance_key(item_definition.key)
	if not _item_manager.take(item_definition.key):
		return ""
	return purchase_key


func _is_position_inside_shop(world_position: Vector2) -> bool:
	if _shop_area == null:
		return false
	var shape_node: CollisionShape2D = null
	for child in _shop_area.get_children():
		if child is CollisionShape2D:
			shape_node = child
			break
	if shape_node == null:
		return false
	var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rectangle == null:
		return false
	var half: Vector2 = rectangle.size * 0.5
	var center: Vector2 = _shop_area.global_position + shape_node.position
	return Rect2(center - half, rectangle.size).has_point(world_position)


func _cursor_position() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return global_position
	return get_global_mouse_position()


func _on_balance_changed(_balance: int) -> void:
	_refresh_case_overlay()


# Case overlay gates on ownership and affordability; neither changes on equip/unequip.
func _on_item_level_changed(item_key: String) -> void:
	if item_definition != null and item_key == item_definition.key:
		_refresh_case_overlay()


func _refresh_case_overlay() -> void:
	if case_overlay == null:
		return
	if is_owned():
		case_overlay.visible = false
		return
	case_overlay.visible = not can_be_owned()
