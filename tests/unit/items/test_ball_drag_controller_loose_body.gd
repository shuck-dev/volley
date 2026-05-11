## SH-332: covers the register_loose_body refactor on BallDragController.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const HeldBodyScene: PackedScene = preload("res://scenes/items/held_body.tscn")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")

var _controller: BallDragController
var _item_manager: Node


func before_each() -> void:
	_item_manager = ItemFactory.create_manager(self)
	_item_manager.items.assign([TrainingBall] as Array[ItemDefinition])
	_controller = BallDragControllerScript.new()
	_controller.configure(_item_manager, null, null, null)
	add_child_autofree(_controller)


func _make_body() -> HeldBody:
	var body: HeldBody = HeldBodyScene.instantiate()
	body.item_key = TrainingBall.key
	add_child_autofree(body)
	return body


func test_register_loose_body_marks_item_loose_in_venue() -> void:
	var body: HeldBody = _make_body()
	_controller.register_loose_body(body)
	assert_true(
		_item_manager.is_loose_in_venue(TrainingBall.key),
		"register_loose_body promotes the key to loose-in-venue",
	)


func test_register_loose_body_wires_grab_for_regrab() -> void:
	var body: HeldBody = _make_body()
	_controller.register_loose_body(body)
	assert_true(
		body.grabbed.get_connections().size() > 0,
		"register_loose_body subscribes to the body's grab signal for re-grab",
	)


func test_register_loose_body_clears_overlay_on_body_free() -> void:
	var body: HeldBody = _make_body()
	_controller.register_loose_body(body)
	assert_true(_item_manager.is_loose_in_venue(TrainingBall.key))
	body.queue_free()
	await get_tree().process_frame
	assert_false(
		_item_manager.is_loose_in_venue(TrainingBall.key),
		"tree_exited handler clears the loose-in-venue overlay so the rack can re-show the slot",
	)


func test_register_loose_body_null_input_is_a_no_op() -> void:
	_controller.register_loose_body(null)
	assert_false(_item_manager.is_loose_in_venue(TrainingBall.key))


func test_get_loose_body_host_returns_a_node() -> void:
	# Without a reconciler the host falls back to the controller's parent.
	var host: Node = _controller.get_loose_body_host()
	assert_not_null(
		host, "loose-body host is always resolvable so callers can parent unconditionally"
	)
