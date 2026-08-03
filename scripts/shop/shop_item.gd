class_name ShopItem
extends Node2D

signal pickup_started(ball_key: String)
signal drop_completed(ball_key: String, position: Vector2, purchased: bool)

@export var pickup_area: Area2D
@export var case_overlay: Node2D

var ball_definition: BallDefinition

var _ball_manager: BallManager
var _ball_instance: Node
var _shop_area: Area2D
var _held_token: Node2D = null
var _mouse_button_down: bool = false


func configure(ball_manager: Node, definition: BallDefinition) -> void:
	_ball_manager = ball_manager
	ball_definition = definition
	_build_ball()
	_refresh_case_overlay()


## The Shop scene injects its own ShopArea so release detection can hit-test against it.
func bind_shop_area(area: Area2D) -> void:
	_shop_area = area


func can_be_owned() -> bool:
	if ball_definition == null or _ball_manager == null:
		return false
	return _ball_manager.can_acquire(ball_definition.key)


func _ready() -> void:
	if _ball_manager == null:
		_ball_manager = BallManager

	if pickup_area != null and not pickup_area.input_event.is_connected(_on_input_event):
		pickup_area.input_event.connect(_on_input_event)

	_ball_manager.soul_balance_changed.connect(_on_balance_changed)
	_ball_manager.item_level_changed.connect(_on_item_level_changed)

	_refresh_case_overlay()


func _process(_delta: float) -> void:
	if _held_token == null:
		return

	var cursor: Vector2 = _cursor_position()
	_held_token.global_position = cursor

	if not _mouse_button_down:
		attempt_release(cursor)


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


func _build_ball() -> void:
	if ball_definition == null or ball_definition.scene == null:
		return

	if _ball_instance != null and is_instance_valid(_ball_instance):
		_ball_instance.queue_free()

	_ball_instance = ball_definition.scene.instantiate()
	add_child(_ball_instance)

	(_ball_instance as Ball).enter_stored()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse_button.pressed and can_be_owned() and _held_token == null:
		_start_drag()


## Test seam / production entry. Begins the held-token gesture from the item's current spot.
func start_drag() -> bool:
	if _held_token != null:
		return false

	if not can_be_owned():
		return false

	_start_drag()

	return true


## Tries to release item to a drop target
func attempt_release(release_position: Vector2) -> bool:
	if _held_token == null:
		return false

	var inside_shop: bool = _is_position_inside_shop(release_position)
	if not inside_shop:
		if not can_be_owned():
			_finalise_gesture(release_position, false)
			visible = true
			return true

		var controller: ItemDragController = _drag_controller()
		if controller == null:
			return false

		var spawned: bool = controller.try_purchase_and_spawn(
			ball_definition.key, release_position, _release_velocity()
		)
		if not spawned:
			return false

		_finalise_gesture(release_position, true)

		visible = false

		return true

	_finalise_gesture(release_position, false)
	visible = true
	return true


func _drag_controller() -> ItemDragController:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"drag_controller") as ItemDragController


func _release_velocity() -> Vector2:
	return BallManager.get_default_ball_launch_velocity()


func _finalise_gesture(release_position: Vector2, purchased: bool) -> void:
	if _held_token != null:
		_held_token.queue_free()
	_held_token = null
	drop_completed.emit(ball_definition.key, release_position, purchased)


func _start_drag() -> void:
	var token: Node2D = Node2D.new()
	token.name = "HeldToken_%s" % ball_definition.key
	if ball_definition != null and ball_definition.scene != null:
		var ball_instance: Node = ball_definition.scene.instantiate()
		token.add_child(ball_instance)
		(ball_instance as Ball).enter_stored()
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
	# Hide the source slot during the drag so the player sees one item, not two (SH-251).
	visible = false
	_mouse_button_down = true
	pickup_started.emit(ball_definition.key)


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


# Case overlay gates on ownership and affordability; neither changes on activate/deactivate.
func _on_item_level_changed(ball_key: String) -> void:
	if ball_definition != null and ball_key == ball_definition.key:
		_refresh_case_overlay()


func _refresh_case_overlay() -> void:
	if case_overlay == null:
		return
	case_overlay.visible = not can_be_owned()
