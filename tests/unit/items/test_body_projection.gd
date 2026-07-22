## Body projection decides whether a ball physically fits at a drop position: clear accepts, an
## overlapping body blocks, and the projection footprint widens with the placement scale.
extends GutTest

const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")


func after_each() -> void:
	await get_tree().process_frame


func _make_ball_definition(key: String, radius: float = 12.0) -> ItemDefinition:
	var item: ItemDefinition = ItemTestHelpersScript.make_ball_item(key)
	var shape := CircleShape2D.new()
	shape.radius = radius
	item.at_rest_shape = shape
	return item


func _make_static_wall(host: Node, position: Vector2, size: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	wall.add_child(collision)
	host.add_child(wall)
	return wall


func _make_harness(definitions: Array) -> Dictionary:
	var manager: Node = ItemFactory.create_manager(self)
	manager.items.assign(definitions as Array[ItemDefinition])
	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	var target: CourtDropTarget = CourtDropTargetScript.new()
	(
		target
		. configure(
			manager,
			reconciler,
			host.get_world_2d(),
		)
	)
	add_child_autofree(target)
	return {"host": host, "reconciler": reconciler, "target": target, "manager": manager}


func test_clear_position_is_accepted() -> void:
	var harness: Dictionary = _make_harness([_make_ball_definition("ball_alpha")])
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(target.can_accept("ball_alpha", Vector2(0, 0)))


func test_an_obstacle_blocks_the_drop() -> void:
	var harness: Dictionary = _make_harness([_make_ball_definition("ball_alpha", 20.0)])
	_make_static_wall(harness["host"], Vector2(100, 0), Vector2(80, 80))
	# Two physics frames so the static body's shape is registered with the space state.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_false(
		target.can_accept("ball_alpha", Vector2(100, 0)),
		"projection rejects when a body sits directly under the candidate position",
	)


func test_scale_widens_the_projection_until_it_blocks() -> void:
	# Wall edge sits between the strict half-extent 10 and the widened 15, so only 1.5x overlaps.
	var item: ItemDefinition = ItemTestHelpersScript.make_ball_item("rect_ball")
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(20, 20)  # half-extent 10 each side
	item.at_rest_shape = rect_shape
	var harness: Dictionary = _make_harness([item])
	_make_static_wall(harness["host"], Vector2(19, 0), Vector2(10, 10))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(target.can_accept("rect_ball", Vector2.ZERO, 1.0), "clears at strict scale")
	assert_false(
		target.can_accept("rect_ball", Vector2.ZERO, 1.5),
		"the widened footprint overlaps the adjacent wall",
	)
