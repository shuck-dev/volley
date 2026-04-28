## SH-287: CourtDropTarget shape-scaling branches and bounds-zero guard.
## Splits from test_drop_targets.gd to keep each suite under the public-method cap.
extends GutTest

const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")


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
	reconciler.configure(manager, host)
	add_child_autofree(reconciler)
	var target: CourtDropTarget = CourtDropTargetScript.new()
	(
		target
		. configure(
			manager,
			reconciler,
			host.get_world_2d(),
			Rect2(Vector2(-600, -400), Vector2(1200, 800)),
		)
	)
	return {"host": host, "reconciler": reconciler, "target": target, "manager": manager}


func test_court_target_scales_rectangle_at_rest_shape() -> void:
	# Items with a RectangleShape2D at-rest shape should scale through the Rectangle branch
	# of _scaled_shape. Place a wall snug against a candidate position; strict (1.0) clears
	# but the 1.5x widened probe must overlap.
	var rect_item: ItemDefinition = ItemTestHelpersScript.make_ball_item("rect_ball")
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(20, 20)  # half-extent 10 each side
	rect_item.at_rest_shape = rect_shape
	var harness: Dictionary = _make_harness([rect_item])
	# Wall left edge at x=14 (half 5 + center 19). Strict half-extent 10 reaches x=10
	# (clear). 1.5x scaled rect has half-extent 15 -> reaches x=15 (overlap).
	_make_static_wall(harness["host"], Vector2(19, 0), Vector2(10, 10))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(
		target.can_accept("rect_ball", Vector2.ZERO, 1.0), "rectangle clears at strict scale"
	)
	assert_false(
		target.can_accept("rect_ball", Vector2.ZERO, 1.5),
		"rectangle scaled 1.5x overlaps the adjacent wall",
	)


func test_court_target_scales_capsule_at_rest_shape() -> void:
	# Items with a CapsuleShape2D at-rest shape should scale through the Capsule branch of
	# _scaled_shape. Same setup as the rectangle case; strict clears, 1.5x overlaps.
	var cap_item: ItemDefinition = ItemTestHelpersScript.make_ball_item("cap_ball")
	var capsule := CapsuleShape2D.new()
	capsule.radius = 8.0
	capsule.height = 24.0
	cap_item.at_rest_shape = capsule
	var harness: Dictionary = _make_harness([cap_item])
	# Capsule reaches +radius (8) horizontally at strict; +12 at 1.5x. Wall left edge at 10.
	_make_static_wall(harness["host"], Vector2(15, 0), Vector2(10, 10))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(target.can_accept("cap_ball", Vector2.ZERO, 1.0), "capsule clears at strict scale")
	assert_false(
		target.can_accept("cap_ball", Vector2.ZERO, 1.5),
		"capsule scaled 1.5x overlaps the adjacent wall",
	)


func test_court_target_zero_bounds_guard_passes_through_position() -> void:
	# An un-configured court (zero-sized bounds) must pass positions through clamp_to_rect
	# rather than collapsing them to the origin and silently breaking acceptance.
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	var manager: Node = ItemFactory.create_manager(self)
	manager.items.assign([ball_alpha] as Array[ItemDefinition])
	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager, host)
	add_child_autofree(reconciler)
	var target: CourtDropTarget = CourtDropTargetScript.new()
	target.configure(manager, reconciler, host.get_world_2d(), Rect2())
	await get_tree().physics_frame
	# With zero-bounds, clamp_to_rect returns the position unchanged so the projection runs
	# at the candidate, not the origin. An empty court accepts anywhere.
	assert_true(
		target.can_accept("ball_alpha", Vector2(500, 500)),
		"zero-bounds guard preserves the candidate position",
	)
