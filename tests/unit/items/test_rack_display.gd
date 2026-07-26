## SH-99 rack display renders every owned-but-inactive item.
extends GutTest

const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")


func after_each() -> void:
	await get_tree().process_frame


func _stub_art() -> PackedScene:
	var scene := PackedScene.new()
	# PackedScene.pack snapshots the node but does not take ownership; freeing avoids a CanvasItem RID leak at exit.
	var template := ItemArt.new()
	scene.pack(template)
	template.free()
	return scene


func _make_item(item_key: String) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = item_key
	item.base_cost = 100
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = []
	item.art = _stub_art()
	return item


func _make_manager_with(items: Array) -> Node:
	var manager: Node = ItemFactory.create_manager(self)
	var typed_items: Array[ItemDefinition] = []
	for item in items:
		typed_items.append(item)
	manager.items.assign(typed_items)
	return manager


func _make_rack(manager: Node) -> Node2D:
	var rack: Node2D = RackDisplayScript.new()
	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)
	for index in 8:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)
	rack.slot_container = slot_container
	rack.configure(manager)
	add_child_autofree(rack)
	return rack


func test_rack_scene_drop_target_accepts_drop() -> void:
	var ball := _make_item("ball_alpha")
	var manager: Node = _make_manager_with([ball])

	var ball_rack_scene: PackedScene = load("res://scenes/ball_rack.tscn")
	var ball_rack_instance: Node = ball_rack_scene.instantiate()

	var rack_target: RackDropTarget = (
		ball_rack_instance.get_node("RackDropTarget") as RackDropTarget
	)
	rack_target.item_manager = manager

	add_child_autofree(ball_rack_instance)

	assert_true(
		rack_target.can_accept("ball_alpha", ball_rack_instance.global_position),
		"ball rack drop target should accept a matching ball at the rack position",
	)


func test_hide_slot_for_hides_only_the_matching_item() -> void:
	# SH-332: rack hides the source slot during a grab so the player sees one body, not two.
	var alpha := _make_item("ball_alpha")
	var beta := _make_item("ball_beta")
	var manager: Node = _make_manager_with([alpha, beta])
	manager.economy.soul_balance = 10000
	var rack := _make_rack(manager)
	manager.take(alpha.key)
	manager.take(beta.key)
	var alpha_key: String = "ball_alpha_1"
	var beta_key: String = "ball_beta_1"
	await get_tree().process_frame

	rack.refresh()
	await get_tree().process_frame
	rack.hide_slot_for(alpha_key)

	for child in rack.slot_container.get_children():
		if not (child is Node2D) or not String(child.name).begins_with("Slot_"):
			continue
		var key: String = child.get_meta(&"item_key", "")
		if key == alpha_key:
			assert_false(child.visible, "grabbed slot is hidden during the gesture")
		elif key == beta_key:
			assert_true(child.visible, "non-grabbed slots stay visible")


func test_get_slot_position_for_returns_world_position_for_known_key() -> void:
	var ball := _make_item("ball_alpha")
	var manager: Node = _make_manager_with([ball])
	manager.economy.soul_balance = 1000
	var rack := _make_rack(manager)
	manager.take(ball.key)

	var position: Vector2 = rack.get_slot_position_for(ball.key)
	# First slot marker sits at local (0, 0); rack is at the origin so global == local.
	assert_eq(position, Vector2.ZERO, "first stored item resolves to the first slot marker")


func test_get_slot_position_for_returns_zero_for_unknown_key() -> void:
	var manager: Node = _make_manager_with([])
	var rack := _make_rack(manager)

	assert_eq(
		rack.get_slot_position_for("nonexistent"),
		Vector2.ZERO,
		"unknown keys return the sentinel Vector2.ZERO",
	)


func _make_reconciler(manager: Node) -> BallReconciler:
	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	add_child_autofree(reconciler)
	return reconciler


func _make_rack_with_reconciler(manager: Node, reconciler: BallReconciler) -> Node2D:
	var rack: Node2D = RackDisplayScript.new()
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
	rack.configure_reconciler(reconciler)
	add_child_autofree(rack)
	return rack


func test_owned_items_show_on_the_rack() -> void:
	var ball := _make_item("ball_alpha")
	var manager: Node = _make_manager_with([ball])
	manager.economy.soul_balance = 1000
	var rack: Node2D = _make_rack(manager)
	manager.take(ball.key)
	rack.refresh()
	var instance_key: String = "ball_alpha_1"

	var displayed: Array[String] = rack.get_displayed_keys()
	assert_eq(displayed.size(), 1, "rack should show the owned item after take and refresh")
	assert_eq(displayed[0], instance_key)


func test_grab_removes_item_from_the_rack() -> void:
	var ball := _make_item("ball_alpha")
	var manager: Node = _make_manager_with([ball])
	manager.economy.soul_balance = 1000
	var reconciler: BallReconciler = _make_reconciler(manager)
	var rack: Node2D = _make_rack_with_reconciler(manager, reconciler)
	manager.take(ball.key)
	var instance_key := "ball_alpha_1"
	reconciler._create_stored(instance_key, Vector2.ZERO)
	rack.refresh()

	assert_eq(rack.get_displayed_keys().size(), 1, "precondition: rack shows the owned item")

	var drop_target: Area2D = Area2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	drop_target.add_child(shape)
	add_child_autofree(drop_target)

	var drag: ItemDragController = ItemDragControllerScript.new()
	drag.configure(manager, rack, drop_target, reconciler)
	add_child_autofree(drag)

	drag.grab_from_rack(instance_key)
	rack.refresh()

	assert_eq(rack.get_displayed_keys().size(), 0, "grab should remove the item from the rack")


func _find_slot(rack: Node2D, item_key: String) -> Node2D:
	for child in rack.slot_container.get_children():
		if child is Node2D and child.get_meta(&"item_key", "") == item_key:
			return child
	return null
