# gdlint:ignore = max-public-methods
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
const CharacterDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/character_drop_target.gd"
)
const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")
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
	manager.economy.friendship_point_balance = 10000
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


# --- CharacterDropTarget --------------------------------------------------------------


func _make_character_target_harness(
	manager: Node, area_position: Vector2 = Vector2.ZERO
) -> Dictionary:
	var area: Area2D = _make_drop_area(area_position, Vector2(40, 80))
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var target: DropTarget = CharacterDropTargetScript.new()
	target.configure(manager, area, timeout)
	return {"area": area, "timeout": timeout, "target": target}


# Forces the timeout state machine into AT_EQUIP_POSE without driving a tween-driven walk.
func _force_at_equip_pose(timeout: TimeoutController) -> void:
	timeout._state = TimeoutController.State.AT_EQUIP_POSE


func test_character_drop_target_accepts_equipment_at_equip_pose_with_capacity() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_a")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_a")
	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])
	assert_true(harness["target"].can_accept("gear_a", Vector2.ZERO))


func test_character_drop_target_rejects_outside_equip_pose() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_b")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_b")
	var harness: Dictionary = _make_character_target_harness(manager)
	# Timeout left in IDLE.
	assert_false(harness["target"].can_accept("gear_b", Vector2.ZERO))


func test_character_drop_target_rejects_ball_role() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("ball_alpha")
	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])
	assert_false(harness["target"].can_accept("ball_alpha", Vector2.ZERO))


func test_character_drop_target_rejects_when_capacity_zero() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_c")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_c")
	# Force capacity to zero by stuffing the persisted-EQUIPPED set.
	var cap: int = int(floor(GameRules.base.kit_slots))
	for i in cap:
		manager.state.item_placements["pad_%d" % i] = Placement.EQUIPPED
	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])
	assert_false(harness["target"].can_accept("gear_c", Vector2.ZERO))


func test_character_drop_target_rejects_position_outside_area() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_d")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_d")
	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])
	assert_false(harness["target"].can_accept("gear_d", Vector2(9999, 9999)))


func test_character_drop_target_accept_equips_and_emits_no_refusal() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_e")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_e")
	var before: int = manager.get_kit_remaining()
	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])
	watch_signals(manager)
	harness["target"].accept("gear_e", Vector2.ZERO, Vector2.ZERO)
	assert_true(manager.is_on_court("gear_e"))
	assert_eq(manager.get_kit_remaining(), before - 1)
	assert_signal_not_emitted(manager, "equip_refused")


func test_character_drop_target_mounts_visual_on_anchor_and_rack_frees_it() -> void:
	# Equip parents the art at the anchor; rack accept frees it via the equipped_art group.
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_mount")
	equipment.anchor_node_path = NodePath("Sprite/AnkleAnchor")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_mount")

	# Minimal paddle fixture: parent owns the drop area as a sibling of Sprite/AnkleAnchor.
	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	paddle.add_child(sprite)
	var ankle_anchor := Node2D.new()
	ankle_anchor.name = "AnkleAnchor"
	sprite.add_child(ankle_anchor)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)

	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: DropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)
	_force_at_equip_pose(timeout)

	character_target.accept("gear_mount", Vector2.ZERO, Vector2.ZERO)
	var group: StringName = CharacterDropTargetScript.equipped_art_group("gear_mount")
	var mounted: Array = get_tree().get_nodes_in_group(group)
	assert_eq(mounted.size(), 1, "equip mounts one visual under the anchor")
	assert_eq(
		(mounted[0] as Node).get_parent(), ankle_anchor, "visual parents at the resolved anchor"
	)

	var rack_area: Area2D = _make_drop_area(Vector2(-500, 0), Vector2(200, 100))
	var rack_target: RackDropTarget = RackDropTargetScript.new()
	rack_target.configure(manager, rack_area, &"equipment")
	rack_target.accept("gear_mount", Vector2.ZERO, Vector2.ZERO)
	await get_tree().process_frame
	assert_eq(get_tree().get_nodes_in_group(group).size(), 0, "unequip frees the mounted visual")


func test_character_drop_target_hydrates_equipped_visuals_on_configure() -> void:
	# Save-and-reload path: placement is already EQUIPPED before the target wires up.
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_hydrate")
	equipment.anchor_node_path = NodePath("Sprite/AnkleAnchor")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_hydrate")
	manager.state.item_placements["gear_hydrate"] = Placement.EQUIPPED

	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	paddle.add_child(sprite)
	var ankle_anchor := Node2D.new()
	ankle_anchor.name = "AnkleAnchor"
	sprite.add_child(ankle_anchor)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: DropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)

	var group: StringName = CharacterDropTargetScript.equipped_art_group("gear_hydrate")
	var mounted: Array = get_tree().get_nodes_in_group(group)
	assert_eq(mounted.size(), 1, "configure hydrates one visual for the persisted EQUIPPED entry")
	assert_eq((mounted[0] as Node).get_parent(), ankle_anchor)


func test_character_drop_target_unmounts_on_placement_change_to_stored() -> void:
	# Signal-driven teardown: unequip flips placement, handler frees the art.
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_unmount")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_unmount")
	manager.state.item_placements["gear_unmount"] = Placement.EQUIPPED

	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: DropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)
	var group: StringName = CharacterDropTargetScript.equipped_art_group("gear_unmount")
	assert_eq(get_tree().get_nodes_in_group(group).size(), 1, "precondition: hydrated")

	manager.unequip("gear_unmount")
	await get_tree().process_frame
	assert_eq(get_tree().get_nodes_in_group(group).size(), 0, "EQUIPPED->STORED frees the visual")


func test_character_drop_target_mount_is_idempotent_on_repeat_equipped_signal() -> void:
	# Hydrate + a duplicate EQUIPPED emission must not double-mount.
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_idem")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_idem")
	manager.state.item_placements["gear_idem"] = Placement.EQUIPPED

	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: DropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)

	manager.item_placement_changed.emit("gear_idem", Placement.EQUIPPED)
	var group: StringName = CharacterDropTargetScript.equipped_art_group("gear_idem")
	assert_eq(get_tree().get_nodes_in_group(group).size(), 1, "second mount is suppressed")


func test_character_drop_target_falls_back_to_paddle_when_anchor_path_empty() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_root")
	# anchor_node_path left as the default empty NodePath.
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_root")

	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: DropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)
	_force_at_equip_pose(timeout)

	character_target.accept("gear_root", Vector2.ZERO, Vector2.ZERO)
	var mounted: Array = get_tree().get_nodes_in_group(
		CharacterDropTargetScript.equipped_art_group("gear_root")
	)
	assert_eq(mounted.size(), 1)
	assert_eq(
		(mounted[0] as Node).get_parent(), paddle, "empty anchor path falls back to paddle root"
	)


func test_character_drop_target_without_drop_area_rejects() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var target: DropTarget = CharacterDropTargetScript.new()
	target.configure(manager, null, timeout)
	assert_false(target.can_accept("anything", Vector2.ZERO))


func test_equipped_visual_carries_press_area_for_regrab() -> void:
	# Mounted art needs a sub-Area2D so the player can press it to unequip via drag.
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_press")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_press")
	manager.state.item_placements["gear_press"] = Placement.EQUIPPED

	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: CharacterDropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)

	var visual: Node = (
		get_tree().get_nodes_in_group(CharacterDropTargetScript.equipped_art_group("gear_press"))[0]
	)
	var press: Area2D = visual.get_node_or_null("EquippedPressArea") as Area2D
	assert_not_null(press, "mounted visual must carry an EquippedPressArea for regrab")
	assert_true(press.input_pickable, "press area must accept mouse input")

	watch_signals(character_target)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	character_target._on_equipped_press_input(null, event, 0, "gear_press")
	assert_signal_emit_count(character_target, "equipped_art_pressed", 1)


func test_set_equipped_visual_visibility_toggles_the_mounted_art() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_vis")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.friendship_point_balance = 10000
	manager.take("gear_vis")
	manager.state.item_placements["gear_vis"] = Placement.EQUIPPED

	var paddle := Node2D.new()
	paddle.name = "PaddleFixture"
	add_child_autofree(paddle)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var character_target: CharacterDropTarget = CharacterDropTargetScript.new()
	character_target.configure(manager, area, timeout)

	character_target.set_equipped_visual_visibility("gear_vis", false)
	var visual: CanvasItem = (
		get_tree().get_nodes_in_group(CharacterDropTargetScript.equipped_art_group("gear_vis"))[0]
		as CanvasItem
	)
	assert_false(visual.visible, "hide hook flips visibility off")
	character_target.set_equipped_visual_visibility("gear_vis", true)
	assert_true(visual.visible, "reveal hook flips visibility back on")


# --- VenueDropTarget -----------------------------------------------------------------


func test_venue_drop_target_accepts_ball_inside_venue_bounds() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])

	var host := Node.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
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
		reconciler.configure(manager)
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
	manager.economy.friendship_point_balance = 10000
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
	drag._spawn_held_body("base_ball", Vector2.ZERO, false)
	var held_token: Node2D = drag.get_held_body()
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
	# Settle the lift past its window so the held token lands on canonical, mirroring the post-ease state.
	drag._grab_ease_elapsed = drag.grab_ease_duration_s
	drag._apply_grab_ease(1.0, held_token.global_position)
	assert_eq(
		held_token.scale,
		canonical,
		"held-token settles on the canonical token_scale after the SH-297 lift ease",
	)
	assert_not_null(slot_art_holder, "precondition: rack populated at least one slot art holder")
	assert_eq(
		slot_art_holder.scale,
		canonical,
		"rack slot art rendering reads token_scale off the definition",
	)
