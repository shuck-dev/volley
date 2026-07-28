## Body projection decides whether a ball physically fits at a drop position: clear accepts, an
## overlapping body blocks, and a larger candidate shape blocks where a smaller one clears.
extends GutTest

const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/ball_test_helpers.gd")


func after_each() -> void:
	await get_tree().process_frame


func _make_ball_definition(key: String) -> BallDefinition:
	return ItemTestHelpersScript.make_ball_item(key)


func _make_circle_shape(radius: float) -> CircleShape2D:
	var shape := CircleShape2D.new()
	shape.radius = radius
	return shape


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
	var manager: Node = BallFactory.create_manager(self)
	manager.items.assign(definitions as Array[BallDefinition])
	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	var target: CourtDropTarget = CourtDropTargetScript.new()
	target.ball_manager = manager
	target.reconciler = reconciler
	target.add_child(BallTestHelpers.attach_rect_shape(BallTestHelpers.COURT_SIZE))
	host.add_child(target)
	return {"host": host, "reconciler": reconciler, "target": target, "manager": manager}


func test_clear_position_is_accepted() -> void:
	var harness: Dictionary = _make_harness([_make_ball_definition("ball_alpha")])
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(target.can_accept("ball_alpha", Vector2(0, 0), _make_circle_shape(12.0)))


func test_an_obstacle_blocks_the_drop() -> void:
	var harness: Dictionary = _make_harness([_make_ball_definition("ball_alpha")])
	_make_static_wall(harness["host"], Vector2(100, 0), Vector2(80, 80))
	# Two physics frames so the static body's shape is registered with the space state.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_false(
		target.can_accept("ball_alpha", Vector2(100, 0), _make_circle_shape(20.0)),
		"projection rejects when a body sits directly under the candidate position",
	)


func test_larger_candidate_shape_blocks_where_a_smaller_one_clears() -> void:
	# Wall edge sits between the small radius 10 and the larger radius 15, so only the larger overlaps.
	var item: BallDefinition = _make_ball_definition("round_ball")
	var harness: Dictionary = _make_harness([item])
	_make_static_wall(harness["host"], Vector2(19, 0), Vector2(10, 10))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(
		target.can_accept("round_ball", Vector2.ZERO, _make_circle_shape(10.0)),
		"clears with the smaller candidate shape",
	)
	assert_false(
		target.can_accept("round_ball", Vector2.ZERO, _make_circle_shape(15.0)),
		"the larger candidate shape overlaps the adjacent wall",
	)
