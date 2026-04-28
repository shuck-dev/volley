class_name ShopItem
extends Node2D

## Diegetic shop item: pressing starts a held-token drag, releasing outside the
## shop bounds completes the purchase. The drag IS the buy gesture (SH-246).
##
## Shop items are non-physics tokens (SH-258). Only the live `Ball` carries a
## RigidBody2D anywhere in the game; on the table the item is a `Node2D` plus
## art, with an `Area2D` doing input picking.

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, position: Vector2, purchased: bool)

@export var art_holder: Node2D
@export var pickup_area: Area2D
@export var case_overlay: Node2D

var item_definition: ItemDefinition

var _item_manager: Node
var _art_instance: ItemArt
var _shop_area: Area2D
var _held_token: Node2D = null
var _last_input_frame: int = -1
## SH-287: tracks mouse-button state so _process can poll for valid targets when mouse is up.
var _mouse_button_down: bool = false


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
	return _item_manager.get_level(item_definition.key) > 0


func is_dragging() -> bool:
	return _held_token != null


func get_held_token() -> Node2D:
	return _held_token


func _ready() -> void:
	if _item_manager == null:
		_item_manager = ItemManager
	if pickup_area != null and not pickup_area.input_event.is_connected(_on_input_event):
		pickup_area.input_event.connect(_on_input_event)
	_item_manager.friendship_point_balance_changed.connect(_on_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_apply_token_scale()
	_refresh_case_overlay()


func _process(_delta: float) -> void:
	if _held_token == null:
		return
	_held_token.global_position = _cursor_position()
	# SH-287: when mouse is up, poll for a valid commit position so the gesture ends the moment one is reachable.
	if not _mouse_button_down:
		attempt_release(_cursor_position())


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


## Test seam / production entry. Returns true on commit (held token freed, gesture ends);
## false on no valid target (held token stays following the cursor, gesture continues).
## Inside-shop bounds is itself a valid target: cancels back to the slot. Outside-shop only
## commits when the purchase succeeds; insufficient FP keeps the gesture open.
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var inside_shop: bool = _is_position_inside_shop(release_position)
	if inside_shop:
		# Cancel: held token freed, slot visible again, no purchase.
		_finalise_gesture(release_position, false)
		visible = true
		return true

	# Outside shop: only commit if the purchase succeeds.
	var purchased: bool = _complete_purchase()
	if not purchased:
		# Insufficient FP (or otherwise un-takeable). No snap-back; gesture stays open.
		# Held token continues to follow the cursor; the player can drag back into the shop
		# bounds to cancel, or get more FP and try again.
		return false

	# Purchased: hand the held position off to BallDragController so the body-projection
	# target loop decides whether the new ball lands on the court (SH-287, SH-320 fix) or
	# falls through to the rack as a token. Held visual freed by the controller's
	# bring_into_play flow when the court accepts; otherwise we free it locally.
	_route_purchased_to_court(release_position)
	_finalise_gesture(release_position, true)
	visible = false
	return true


## Hands off to BallDragController so the just-purchased item can land on the court at
## the released position when the body projection passes (SH-320).
func _route_purchased_to_court(release_position: Vector2) -> bool:
	if item_definition == null:
		return false
	if item_definition.role != &"ball":
		return false
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var controller: Node = tree.get_first_node_in_group(&"drag_controller")
	if controller == null or not controller.has_method("spawn_purchased_at"):
		return false
	return controller.spawn_purchased_at(item_definition.key, release_position, _release_velocity())


func _release_velocity() -> Vector2:
	if _item_manager != null and _item_manager.has_method("get_default_ball_launch_velocity"):
		return _item_manager.get_default_ball_launch_velocity()
	return Vector2.ZERO


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
	token.global_position = _cursor_position()
	_held_token = token
	# Hide the source slot during the drag so the player sees one item, not two (SH-251).
	visible = false
	_mouse_button_down = true
	pickup_started.emit(item_definition.key)


func _complete_purchase() -> bool:
	if is_owned():
		return false
	if not can_be_owned():
		return false
	return _item_manager.take(item_definition.key)


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
