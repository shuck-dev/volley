extends GutTest

const ShopDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/shop_drop_target.gd"
)
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


func test_shop_target_accepts_inside_shop_zone() -> void:
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.position = Vector2(100, 0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(200, 100)
	shape.shape = rect
	target.add_child(shape)
	add_child_autofree(target)
	assert_true(target.can_accept("ball_alpha", Vector2(100, 0)))
	assert_false(target.can_accept("ball_alpha", Vector2(900, 900)))


func test_rack_target_accepts_matching_ball_role() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball: ItemDefinition = ItemTestHelpers.make_ball_item("ball_alpha")
	manager.items.assign([ball] as Array[ItemDefinition])
	var target: RackDropTarget = RackDropTargetScript.new()
	target.item_manager = manager
	target.role = &"ball"
	target.position = Vector2(-500, 0)
	var rack_shape := CollisionShape2D.new()
	var rack_rect := RectangleShape2D.new()
	rack_rect.size = Vector2(200, 100)
	rack_shape.shape = rack_rect
	target.add_child(rack_shape)
	add_child_autofree(target)
	assert_true(target.can_accept("ball_alpha", Vector2(-500, 0)))


func test_court_target_rejects_equipment_role() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = ItemTestHelpers.make_equipment_item("grip")
	manager.items.assign([equipment] as Array[ItemDefinition])
	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	var target: CourtDropTarget = CourtDropTargetScript.new()
	target.item_manager = manager
	target.reconciler = reconciler
	target.court_bounds = Rect2()
	add_child_autofree(target)
	assert_false(target.can_accept("grip", Vector2.ZERO))


func test_venue_target_accepts_inside_venue_bounds() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball: ItemDefinition = ItemTestHelpers.make_ball_item("ball_alpha")
	manager.items.assign([ball] as Array[ItemDefinition])
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	var venue := Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	var court := Rect2(Vector2(-600, -400), Vector2(1200, 800))
	var target: VenueDropTarget = VenueDropTargetScript.new()
	target.item_manager = manager
	target.reconciler = reconciler
	target.venue_bounds = venue
	add_child_autofree(target)
	assert_true(target.can_accept("ball_alpha", Vector2(1500, 50)))
	assert_false(target.can_accept("ball_alpha", Vector2(9999, 9999)))
