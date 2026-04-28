## SH-287: drop targets validate releases through bounds and body projection.
extends GutTest

const DropTargetScript: GDScript = preload("res://scripts/items/drop_target.gd")
const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)
const ShopDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/shop_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")
const BaseBall: ItemDefinition = preload("res://resources/items/base_ball.tres")


func _make_ball_definition(key: String, radius: float = 12.0) -> ItemDefinition:
	var item: ItemDefinition = ItemTestHelpersScript.make_ball_item(key)
	var shape := CircleShape2D.new()
	shape.radius = radius
	item.at_rest_shape = shape
	return item


func _make_equipment_definition(key: String) -> ItemDefinition:
	var item: ItemDefinition = ItemTestHelpersScript.make_ball_item(key)
	item.role = &"equipment"
	return item


func _make_drop_area(position: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


# --- DropTarget base contract --------------------------------------------------------


func test_default_drop_target_rejects_everything() -> void:
	var target: DropTarget = DropTargetScript.new()
	assert_false(target.can_accept("anything", Vector2.ZERO))


func test_default_drop_target_accept_is_a_no_op() -> void:
	var target: DropTarget = DropTargetScript.new()
	target.accept("anything", Vector2.ZERO, Vector2.ZERO)
	assert_true(true)


# --- ShopDropTarget ------------------------------------------------------------------


func test_shop_drop_target_accepts_inside_shop_area() -> void:
	var area: Area2D = _make_drop_area(Vector2(100, 0), Vector2(200, 100))
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.configure(area)
	assert_true(target.can_accept("ball_alpha", Vector2(120, 0)))


func test_shop_drop_target_rejects_outside_shop_area() -> void:
	var area: Area2D = _make_drop_area(Vector2(100, 0), Vector2(50, 50))
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.configure(area)
	assert_false(target.can_accept("ball_alpha", Vector2(500, 500)))


func test_shop_drop_target_accept_is_a_silent_no_op() -> void:
	var area: Area2D = _make_drop_area(Vector2(0, 0), Vector2(100, 100))
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.configure(area)
	target.accept("ball_alpha", Vector2.ZERO, Vector2.ZERO)
	assert_true(true)


func test_shop_drop_target_without_area_rejects() -> void:
	var target: ShopDropTarget = ShopDropTargetScript.new()
	assert_false(target.can_accept("ball_alpha", Vector2.ZERO))


# --- RackDropTarget ------------------------------------------------------------------


func test_rack_drop_target_accepts_role_match_inside_area() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])

	var area: Area2D = _make_drop_area(Vector2(-500, 0), Vector2(200, 100))
	var target: RackDropTarget = RackDropTargetScript.new()
	target.configure(manager, area, &"ball")
	assert_true(target.can_accept("ball_alpha", Vector2(-500, 0)))


func test_rack_drop_target_rejects_role_mismatch() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("grip_x")
	manager.items.assign([equipment] as Array[ItemDefinition])

	var area: Area2D = _make_drop_area(Vector2(-500, 0), Vector2(200, 100))
	var ball_target: RackDropTarget = RackDropTargetScript.new()
	ball_target.configure(manager, area, &"ball")
	assert_false(ball_target.can_accept("grip_x", Vector2(-500, 0)))


func test_rack_drop_target_accept_deactivates_an_on_court_item() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])
	manager._progression.friendship_point_balance = 10000
	manager.take("ball_alpha")
	manager.activate("ball_alpha")
	assert_true(manager.is_on_court("ball_alpha"), "precondition: on court")

	var area: Area2D = _make_drop_area(Vector2(-500, 0), Vector2(200, 100))
	var target: RackDropTarget = RackDropTargetScript.new()
	target.configure(manager, area, &"ball")
	target.accept("ball_alpha", Vector2.ZERO, Vector2.ZERO)
	assert_false(manager.is_on_court("ball_alpha"))


func test_rack_drop_target_without_drop_area_rejects() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var target: RackDropTarget = RackDropTargetScript.new()
	target.configure(manager, null, &"ball")
	assert_false(target.can_accept("ball_alpha", Vector2.ZERO))


# --- VenueDropTarget -----------------------------------------------------------------


func test_venue_drop_target_accepts_ball_inside_venue_bounds() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])

	var host := Node.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager, host)
	add_child_autofree(reconciler)

	var venue := Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	var court := Rect2(Vector2(-600, -400), Vector2(1200, 800))
	var target: VenueDropTarget = VenueDropTargetScript.new()
	target.configure(manager, reconciler, venue, court)
	assert_true(target.can_accept("ball_alpha", Vector2(1500, 50)))
	# Inclusive max-edge: Rect2.has_point treats max as exclusive without the guard.
	assert_true(target.can_accept("ball_alpha", Vector2(2000, 1200)))


func test_venue_drop_target_rejects_outside_venue() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])

	var venue := Rect2(Vector2(-100, -100), Vector2(200, 200))
	var court := Rect2(Vector2(-50, -50), Vector2(100, 100))
	var target: VenueDropTarget = VenueDropTargetScript.new()
	target.configure(manager, null, venue, court)
	assert_false(target.can_accept("ball_alpha", Vector2(9999, 9999)))


# --- CourtDropTarget body projection -------------------------------------------------


class _PhysicsHarness:
	extends Node2D

	## Parents balls/walls under a tree-resident Node2D so they share its `World2D`.

	static func make(test: GutTest, manager: Node, definitions: Array) -> Dictionary:
		manager.items.assign(definitions as Array[ItemDefinition])
		var host := Node2D.new()
		test.add_child_autofree(host)
		var reconciler: BallReconciler = BallReconcilerScript.new()
		reconciler.configure(manager, host)
		test.add_child_autofree(reconciler)
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


func test_court_target_accepts_clear_position() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	var harness: Dictionary = _PhysicsHarness.make(self, manager, [ball_alpha])
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(target.can_accept("ball_alpha", Vector2(0, 0)))


func test_court_target_rejects_when_wall_overlaps_projection() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha", 20.0)
	var harness: Dictionary = _PhysicsHarness.make(self, manager, [ball_alpha])
	_make_static_wall(harness["host"], Vector2(100, 0), Vector2(80, 80))
	# Two physics frames so the static body's shape is registered with the space state.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_false(
		target.can_accept("ball_alpha", Vector2(100, 0)),
		"projection rejects when a wall sits directly under the candidate position",
	)


func test_court_target_rejects_ball_on_ball_stack() -> void:
	# StaticBody2D stands in for a placed ball so the body stays put across physics frames.
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha", 20.0)
	var harness: Dictionary = _PhysicsHarness.make(self, manager, [ball_alpha])
	_make_static_wall(harness["host"], Vector2(50, 50), Vector2(40, 40))
	# Two frames so the static body's RID is in the space state.
	await get_tree().physics_frame
	await get_tree().physics_frame

	var target: CourtDropTarget = harness["target"]
	assert_false(
		target.can_accept("ball_alpha", Vector2(50, 50)),
		"a ball cannot land directly on top of an existing body",
	)
	assert_true(
		target.can_accept("ball_alpha", Vector2(-200, -200)),
		"a clear position elsewhere on the court still accepts",
	)


func test_court_target_rejects_position_outside_court_bounds() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	var harness: Dictionary = _PhysicsHarness.make(self, manager, [ball_alpha])
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_false(
		target.can_accept("ball_alpha", Vector2(2000, 0)),
		"positions outside the court bounds do not match the strict court target",
	)


func test_court_target_rejects_equipment_role() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("grip_y")
	var harness: Dictionary = _PhysicsHarness.make(self, manager, [equipment])
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_false(target.can_accept("grip_y", Vector2.ZERO))


func test_court_target_widens_with_expansion_ring_scale() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha", 12.0)
	var harness: Dictionary = _PhysicsHarness.make(self, manager, [ball_alpha])
	await get_tree().physics_frame
	var target: CourtDropTarget = harness["target"]
	assert_true(target.can_accept("ball_alpha", Vector2.ZERO, 1.0))
	assert_true(target.can_accept("ball_alpha", Vector2.ZERO, 1.5))


# --- Cross-container size identity (SH-261 + SH-287 AC) -----------------------------


func test_item_definition_carries_at_rest_shape_for_ball_items() -> void:
	assert_not_null(BaseBall.at_rest_shape, "base ball should carry an at_rest_shape after SH-287")
	assert_true(BaseBall.at_rest_shape is CircleShape2D)


func test_token_scale_remains_canonical_across_items() -> void:
	# Pins held-token, rack-slot, and definition scales to the single source of truth (SH-261).
	const BallDragControllerScript: GDScript = preload(
		"res://scripts/items/ball_drag_controller.gd"
	)
	const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")

	var manager: Node = ItemFactory.create_manager(self)
	manager.items.assign([BaseBall] as Array[ItemDefinition])
	manager._progression.friendship_point_balance = 10000
	manager.take("base_ball")

	# 1. Held token through the drag controller.
	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = &"ball"
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)
	for index in 4:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	rack.slot_container = slot_container
	rack.configure(manager)
	add_child_autofree(rack)

	var drag: BallDragController = BallDragControllerScript.new()
	drag.configure(manager, rack, null, null)
	add_child_autofree(drag)
	drag._spawn_held_token("base_ball", Vector2.ZERO, false)
	var held_token: Node2D = drag.get_held_token()
	assert_not_null(held_token, "precondition: held token spawned")

	rack.refresh()
	var slot_art_holder: Node2D = null
	for slot in slot_container.get_children():
		var holder: Node = slot.get_node_or_null("ArtHolder")
		if holder is Node2D:
			slot_art_holder = holder
			break

	var canonical: Vector2 = BaseBall.token_scale

	assert_eq(canonical, Vector2(1.5, 1.5), "definition pins the canonical token_scale")
	assert_eq(
		held_token.scale, canonical, "held-token rendering reads token_scale off the definition"
	)
	assert_not_null(slot_art_holder, "precondition: rack populated at least one slot art holder")
	assert_eq(
		slot_art_holder.scale,
		canonical,
		"rack slot art rendering reads token_scale off the definition",
	)
