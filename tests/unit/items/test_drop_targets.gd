extends GutTest

const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)
const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")


func after_each() -> void:
	await get_tree().process_frame


func test_nested_target_accepts_at_its_on_screen_position() -> void:
	var manager: Node = BallFactory.create_manager(self)
	var ball: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	manager.items.assign([ball] as Array[BallDefinition])
	var rack := Node2D.new()
	rack.position = Vector2(-486, 180)
	add_child_autofree(rack)

	var target: RackDropTarget = RackDropTargetScript.new()
	target.ball_manager = manager

	var shape: CollisionShape2D = BallTestHelpers.attach_rect_shape(Vector2(200, 100))
	shape.position = Vector2(40, 0)
	target.add_child(shape)
	rack.add_child(target)

	assert_true(
		target.can_accept("ball_alpha", Vector2(-446, 180), BallTestHelpers.collision_shape),
		"a release over the rack's own shape should land on it",
	)
	assert_false(
		target.can_accept("ball_alpha", Vector2.ZERO, BallTestHelpers.collision_shape),
		"the world origin is nowhere near the rack, so nothing should drop there",
	)


func test_rotated_target_accepts_along_its_turned_edge() -> void:
	var manager: Node = BallFactory.create_manager(self)
	var ball: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	manager.items.assign([ball] as Array[BallDefinition])

	var target: RackDropTarget = RackDropTargetScript.new()
	target.ball_manager = manager
	target.rotation = PI / 2
	target.add_child(BallTestHelpers.attach_rect_shape(Vector2(400, 100)))
	add_child_autofree(target)

	assert_true(
		target.can_accept("ball_alpha", Vector2(0, 180), BallTestHelpers.collision_shape),
		"the long edge turned upright, so a point far along Y is inside",
	)
	assert_false(
		target.can_accept("ball_alpha", Vector2(180, 0), BallTestHelpers.collision_shape),
		"the short edge now runs along X, so the same distance out is outside",
	)


func test_rack_target_accepts_known_item() -> void:
	var manager: Node = BallFactory.create_manager(self)
	var ball: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	manager.items.assign([ball] as Array[BallDefinition])
	var target: RackDropTarget = RackDropTargetScript.new()
	target.ball_manager = manager
	target.position = Vector2(-500, 0)
	target.add_child(BallTestHelpers.attach_rect_shape(Vector2(200, 100)))
	add_child_autofree(target)
	assert_true(target.can_accept("ball_alpha", Vector2(-500, 0), BallTestHelpers.collision_shape))


func test_venue_target_accepts_inside_venue_bounds() -> void:
	var manager: Node = BallFactory.create_manager(self)
	var ball: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	manager.items.assign([ball] as Array[BallDefinition])
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	var target: VenueDropTarget = VenueDropTargetScript.new()
	target.ball_manager = manager
	target.reconciler = reconciler
	target.add_child(BallTestHelpers.attach_rect_shape(BallTestHelpers.VENUE_SIZE))
	add_child_autofree(target)
	assert_true(target.can_accept("ball_alpha", Vector2(1500, 50), BallTestHelpers.collision_shape))
	assert_false(
		target.can_accept("ball_alpha", Vector2(9999, 9999), BallTestHelpers.collision_shape)
	)
