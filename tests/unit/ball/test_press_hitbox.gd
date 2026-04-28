## SH-297 generous press hit-box: live balls accept presses on a wider Area2D so a press
## near a moving ball lands without pixel precision.
extends GutTest

var _ball: Ball
var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	_manager._effect_manager = EffectManager.new()
	(
		_manager
		. items
		. assign(
			[
				preload("res://resources/items/training_ball.tres"),
			]
		)
	)
	add_child_autofree(_manager)


func _spawn_authored_ball() -> Ball:
	# Instantiate the authored .tscn so the press area resolves the real CollisionShape2D.
	var BallScene: PackedScene = preload("res://scenes/ball.tscn")
	var ball: Ball = BallScene.instantiate()
	ball._item_manager = _manager
	add_child_autofree(ball)
	return ball


func test_press_area_exists_after_setup() -> void:
	_ball = _spawn_authored_ball()
	var press_area: Area2D = _ball.get_node_or_null("PressArea") as Area2D
	assert_not_null(press_area, "ball spawns a child Area2D named 'PressArea'")
	assert_true(press_area.input_pickable, "PressArea must accept pointer events")


func test_rigidbody_input_pickable_disabled_so_press_routes_through_area() -> void:
	# The rigid body must not double-fire presses; routing lives on the Area2D alone.
	_ball = _spawn_authored_ball()
	assert_false(_ball.input_pickable, "rigid body input_pickable disabled in favour of PressArea")


func test_press_radius_is_inflated_versus_physics_radius() -> void:
	_ball = _spawn_authored_ball()
	var press_area: Area2D = _ball.get_node("PressArea") as Area2D
	var press_shape: CollisionShape2D = null
	for child in press_area.get_children():
		if child is CollisionShape2D:
			press_shape = child
			break
	assert_not_null(press_shape)
	var press_circle: CircleShape2D = press_shape.shape as CircleShape2D
	assert_not_null(press_circle, "press hit-box is a CircleShape2D")
	var authored_radius: float = _authored_radius_from_ball(_ball)
	assert_almost_eq(
		press_circle.radius,
		authored_radius * Ball.PRESS_HITBOX_INFLATION,
		0.001,
		"press radius equals authored radius * PRESS_HITBOX_INFLATION",
	)


func _authored_radius_from_ball(ball: Ball) -> float:
	for child in ball.get_children():
		if child is CollisionShape2D:
			var shape_node: CollisionShape2D = child
			var circle: CircleShape2D = shape_node.shape as CircleShape2D
			if circle == null:
				continue
			var axis_scale: float = maxf(absf(shape_node.scale.x), absf(shape_node.scale.y))
			return circle.radius * maxf(axis_scale, 0.001)
	return 0.0


func test_press_emits_pressed_signal() -> void:
	# A left-mouse-down event delivered to the press area surfaces as `Ball.pressed`.
	_ball = _spawn_authored_ball()
	watch_signals(_ball)
	var press_area: Area2D = _ball.get_node("PressArea") as Area2D
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true

	_ball._on_input_event(null, event, 0)

	assert_signal_emitted(_ball, "pressed")
