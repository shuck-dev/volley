## Drop targets accept or reject a released item by role, capacity, and the equip pose.
## (Body projection lives in test_body_projection.gd.)
extends GutTest

const CourtDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/court_drop_target.gd"
)
const RackDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/rack_drop_target.gd"
)
const VenueDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/venue_drop_target.gd"
)
const ShopDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/shop_drop_target.gd"
)
const CharacterDropTargetScript: GDScript = preload(
	"res://scripts/items/drop_targets/character_drop_target.gd"
)
const TimeoutControllerScript: GDScript = preload("res://scripts/core/timeout_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")


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


# --- ShopDropTarget ------------------------------------------------------------------


func test_shop_drop_target_accepts_release_inside_shop_zone() -> void:
	# A release inside the shop zone is taken so the gesture cancels back to its source slot.
	var area: Area2D = _make_drop_area(Vector2(100, 0), Vector2(200, 100))
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.configure(area)

	assert_true(target.can_accept("ball_alpha", Vector2(100, 0)))


func test_shop_drop_target_rejects_release_outside_shop_zone() -> void:
	# Outside the zone the shop does not take the release, so the gesture falls through to the next target.
	var area: Area2D = _make_drop_area(Vector2(100, 0), Vector2(50, 50))
	var target: ShopDropTarget = ShopDropTargetScript.new()
	target.configure(area)

	assert_false(target.can_accept("ball_alpha", Vector2(900, 900)))


# --- RackDropTarget ------------------------------------------------------------------


func test_rack_drop_target_accepts_matching_role() -> void:
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

	assert_false(ball_target.can_accept("grip_x", Vector2.ZERO))


func test_rack_drop_target_accept_deactivates_an_on_court_item() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])
	manager.economy.soul_balance = 10000
	manager.take("ball_alpha")
	manager.activate("ball_alpha")
	assert_true(manager.is_on_court("ball_alpha"), "precondition: on court")

	var area: Area2D = _make_drop_area(Vector2(-500, 0), Vector2(200, 100))
	var target: RackDropTarget = RackDropTargetScript.new()
	target.configure(manager, area, &"ball")

	target.accept("ball_alpha", Vector2.ZERO, Vector2.ZERO)

	assert_false(manager.is_on_court("ball_alpha"))


func test_rack_drop_target_accepts_equipment_unequip_outside_equip_pose() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_rack_gate")
	manager.items.assign([equipment] as Array[ItemDefinition])

	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(200, 100))

	var target: RackDropTarget = RackDropTargetScript.new()
	target.configure(manager, area, &"equipment")

	assert_true(
		target.can_accept("gear_rack_gate", Vector2.ZERO),
		"rack-return is unconditional: accepted regardless of timeout state",
	)


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
	manager.economy.soul_balance = 10000
	manager.take("gear_a")

	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])

	assert_true(harness["target"].can_accept("gear_a", Vector2.ZERO))


func test_character_drop_target_rejects_outside_equip_pose() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_b")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.soul_balance = 10000
	manager.take("gear_b")

	var harness: Dictionary = _make_character_target_harness(manager)
	# Timeout left in IDLE.
	assert_false(harness["target"].can_accept("gear_b", Vector2.ZERO))


func test_character_drop_target_rejects_ball_role() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball] as Array[ItemDefinition])
	manager.economy.soul_balance = 10000
	manager.take("ball_alpha")

	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])

	assert_false(harness["target"].can_accept("ball_alpha", Vector2.ZERO))


func test_character_drop_target_rejects_when_capacity_zero() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_c")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.soul_balance = 10000
	manager.take("gear_c")

	# Force capacity to zero by stuffing the persisted-EQUIPPED set.
	var cap: int = int(floor(GameRules.base.kit_slots))
	for i in cap:
		manager.state.item_placements["pad_%d" % i] = Placement.EQUIPPED

	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])

	assert_false(harness["target"].can_accept("gear_c", Vector2.ZERO))


func test_character_drop_target_equips_gear() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_e")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.soul_balance = 10000
	manager.take("gear_e")

	var harness: Dictionary = _make_character_target_harness(manager)
	_force_at_equip_pose(harness["timeout"])

	harness["target"].accept("gear_e", Vector2.ZERO, Vector2.ZERO)

	assert_true(manager.is_on_court("gear_e"))


func test_pressing_equipped_gear_signals_a_regrab() -> void:
	# A left-click on mounted gear emits equipped_art_pressed, which drives the regrab-to-rack flow.
	var manager: Node = ItemFactory.create_manager(self)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var target: CharacterDropTarget = CharacterDropTargetScript.new()
	target.configure(manager, _make_drop_area(Vector2.ZERO, Vector2(40, 80)), timeout, null)
	watch_signals(target)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	target._on_equipped_press_input(null, click, 0, "gear_a")

	assert_signal_emitted(target, "equipped_art_pressed")


func test_configure_re_renders_gear_equipped_before_load() -> void:
	# Save/reload: gear already EQUIPPED in state must re-mount its visual when the target wires up.
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("gear_hydrate")
	manager.items.assign([equipment] as Array[ItemDefinition])
	manager.economy.soul_balance = 10000
	manager.take("gear_hydrate")
	manager.state.item_placements["gear_hydrate"] = Placement.EQUIPPED

	var paddle := Node2D.new()
	add_child_autofree(paddle)
	var area: Area2D = _make_drop_area(Vector2.ZERO, Vector2(40, 80))
	area.reparent(paddle)
	var timeout: TimeoutController = TimeoutControllerScript.new()
	add_child_autofree(timeout)
	var target: CharacterDropTarget = CharacterDropTargetScript.new()
	target.configure(manager, area, timeout, paddle)

	var group: StringName = CharacterDropTargetScript.equipped_art_group("gear_hydrate")
	assert_eq(get_tree().get_nodes_in_group(group).size(), 1, "gear re-renders on load")


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


func test_venue_drop_target_rejects_outside_venue() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = _make_ball_definition("ball_alpha")
	manager.items.assign([ball_alpha] as Array[ItemDefinition])

	var venue := Rect2(Vector2(-100, -100), Vector2(200, 200))
	var court := Rect2(Vector2(-50, -50), Vector2(100, 100))
	var target: VenueDropTarget = VenueDropTargetScript.new()
	target.configure(manager, null, venue, court)
	assert_false(target.can_accept("ball_alpha", Vector2(9999, 9999)))


# --- CourtDropTarget role gate (body projection lives in test_body_projection.gd) ----


func test_court_target_rejects_equipment_role() -> void:
	var manager: Node = ItemFactory.create_manager(self)
	var equipment: ItemDefinition = _make_equipment_definition("grip_y")
	manager.items.assign([equipment] as Array[ItemDefinition])
	var host := Node2D.new()
	add_child_autofree(host)
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	var target: CourtDropTarget = CourtDropTargetScript.new()
	target.configure(
		manager, reconciler, host.get_world_2d(), Rect2(Vector2(-600, -400), Vector2(1200, 800))
	)
	assert_false(target.can_accept("grip_y", Vector2.ZERO))
