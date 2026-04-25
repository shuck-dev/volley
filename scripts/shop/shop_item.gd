class_name ShopItem
extends RigidBody2D

## Diegetic shop item: pressing starts a held-token drag, releasing outside the
## shop bounds completes the purchase. The drag IS the buy gesture (SH-246).

signal pickup_started(item_key: String)
signal drop_completed(item_key: String, position: Vector2, purchased: bool)

@export var art_holder: Node2D
@export var collision_shape: CollisionShape2D
@export var case_overlay: Node2D

var item_definition: ItemDefinition

var _item_manager: Node
var _art_instance: ItemArt
var _shop_area: Area2D
var _held_token: Node2D = null
var _last_input_frame: int = -1


func configure(item_manager: Node, definition: ItemDefinition) -> void:
	_item_manager = item_manager
	item_definition = definition
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
	input_pickable = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	input_event.connect(_on_input_event)
	_item_manager.friendship_point_balance_changed.connect(_on_balance_changed)
	_item_manager.item_level_changed.connect(_on_item_level_changed)
	_refresh_case_overlay()


func _process(_delta: float) -> void:
	if _held_token == null:
		return
	_held_token.global_position = _cursor_position()


# Release handled here so a fast drag that outruns collision still ends the drag.
func _input(event: InputEvent) -> void:
	if _held_token == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
		# Take the release position from the event itself so canvas transforms do not break
		# the inside-shop hit-test, and so headless tests can drive the path deterministically.
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


## Test seam / production entry. Outside shop bounds purchases; inside cancels.
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var token: Node2D = _held_token
	_held_token = null
	token.queue_free()

	var purchased: bool = false
	var inside_shop: bool = _is_position_inside_shop(release_position)
	if not inside_shop:
		purchased = _complete_purchase()

	visible = inside_shop or is_owned() == false
	# Items that purchase successfully leave the shop pool; the shop will despawn them
	# on the next refresh. Until then, hide them so they don't sit visible on the table.
	if purchased:
		visible = false

	drop_completed.emit(item_definition.key, release_position, purchased)
	return true


func _start_drag() -> void:
	var token: Node2D = Node2D.new()
	token.name = "HeldToken_%s" % item_definition.key
	if item_definition != null and item_definition.art != null:
		var art_instance: Node = item_definition.art.instantiate()
		token.add_child(art_instance)
	# Parent at scene root so the held visual follows the cursor without being
	# tied to the item's rigid body.
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		current_scene.add_child(token)
	else:
		add_child(token)
	token.global_position = _cursor_position()
	_held_token = token
	# Hide the source slot's render for the duration of the drag (SH-251) so the
	# player sees one item under their cursor, not the held token alongside the slot.
	visible = false
	pickup_started.emit(item_definition.key)


func _complete_purchase() -> bool:
	if is_owned():
		return false
	if not can_be_owned():
		return false
	return _item_manager.take(item_definition.key)


func _is_position_inside_shop(position: Vector2) -> bool:
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
	return Rect2(center - half, rectangle.size).has_point(position)


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
		_refresh_freeze()
		return
	case_overlay.visible = not can_be_owned()
	_refresh_freeze()


# Cased items freeze kinematically; drag lifecycle controls freeze directly.
func _refresh_freeze() -> void:
	if _held_token != null:
		return
	set_deferred("freeze", not is_owned() and not can_be_owned())
