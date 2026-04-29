## SH-99 rack display renders every owned-but-inactive item of its role.
extends GutTest

const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")


func _stub_art() -> PackedScene:
	var scene := PackedScene.new()
	# PackedScene.pack snapshots the node but does not take ownership; freeing avoids a CanvasItem RID leak at exit.
	var template := Node2D.new()
	scene.pack(template)
	template.free()
	return scene


func _make_item(item_key: String, role: StringName) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = item_key
	item.role = role
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


func _make_rack(role: StringName, manager: Node) -> Node2D:
	var rack: Node2D = RackDisplayScript.new()
	rack.role = role
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


func test_adding_a_ball_item_shows_a_slot_on_the_ball_rack() -> void:
	var ball := _make_item("ball_alpha", &"ball")
	var manager: Node = _make_manager_with([ball])
	manager._progression.friendship_point_balance = 1000
	var rack := _make_rack(&"ball", manager)

	manager.take(ball.key)

	var displayed: Array[String] = rack.get_displayed_keys()
	assert_eq(displayed.size(), 1, "ball rack should render one slot for the new ball item")
	assert_eq(displayed[0], ball.key, "ball rack slot should reference the ball item key")


func test_adding_an_equipment_item_shows_a_slot_on_the_gear_rack() -> void:
	var gear := _make_item("gear_alpha", &"equipment")
	var manager: Node = _make_manager_with([gear])
	manager._progression.friendship_point_balance = 1000
	var rack := _make_rack(&"equipment", manager)

	manager.take(gear.key)

	var displayed: Array[String] = rack.get_displayed_keys()
	assert_eq(displayed.size(), 1, "gear rack should render one slot for the new equipment item")
	assert_eq(displayed[0], gear.key, "gear rack slot should reference the equipment item key")


func test_ball_items_do_not_appear_on_the_gear_rack() -> void:
	var ball := _make_item("ball_beta", &"ball")
	var manager: Node = _make_manager_with([ball])
	manager._progression.friendship_point_balance = 1000
	var rack := _make_rack(&"equipment", manager)

	manager.take(ball.key)

	assert_eq(
		rack.get_displayed_keys().size(),
		0,
		"gear rack should ignore ball-role items",
	)


func test_equipment_items_do_not_appear_on_the_ball_rack() -> void:
	var gear := _make_item("gear_beta", &"equipment")
	var manager: Node = _make_manager_with([gear])
	manager._progression.friendship_point_balance = 1000
	var rack := _make_rack(&"ball", manager)

	manager.take(gear.key)

	assert_eq(
		rack.get_displayed_keys().size(),
		0,
		"ball rack should ignore equipment-role items",
	)


func test_activating_an_item_removes_its_slot() -> void:
	var ball := _make_item("ball_gamma", &"ball")
	var manager: Node = _make_manager_with([ball])
	manager._progression.friendship_point_balance = 1000
	var rack := _make_rack(&"ball", manager)
	manager.take(ball.key)
	assert_eq(
		rack.get_displayed_keys().size(),
		1,
		"precondition: taken ball should render on the rack",
	)

	manager.activate(ball.key)

	assert_eq(
		rack.get_displayed_keys().size(),
		0,
		"activating an item should remove its slot from the rack",
	)


func test_deactivating_an_item_restores_its_slot() -> void:
	var gear := _make_item("gear_gamma", &"equipment")
	var manager: Node = _make_manager_with([gear])
	manager._progression.friendship_point_balance = 1000
	var rack := _make_rack(&"equipment", manager)
	manager.take(gear.key)
	manager.activate(gear.key)
	assert_eq(
		rack.get_displayed_keys().size(),
		0,
		"precondition: activated equipment should not be on the rack",
	)

	manager.deactivate(gear.key)

	assert_eq(
		rack.get_displayed_keys().size(),
		1,
		"deactivating equipment should bring its slot back to the rack",
	)
	assert_eq(rack.get_displayed_keys()[0], gear.key)


func test_court_role_items_never_appear_on_either_rack() -> void:
	var court_item := _make_item("court_alpha", &"court")
	var manager: Node = _make_manager_with([court_item])
	manager._progression.item_levels[court_item.key] = 1

	var ball_rack := _make_rack(&"ball", manager)
	var gear_rack := _make_rack(&"equipment", manager)

	assert_eq(
		ball_rack.get_displayed_keys().size(),
		0,
		"court-role items must not appear on the ball rack",
	)
	assert_eq(
		gear_rack.get_displayed_keys().size(),
		0,
		"court-role items must not appear on the gear rack",
	)


func test_rack_exposes_a_drop_target_child() -> void:
	var ball_rack_scene: PackedScene = load("res://scenes/ball_rack.tscn")
	var gear_rack_scene: PackedScene = load("res://scenes/gear_rack.tscn")
	var ball_rack_instance: Node = ball_rack_scene.instantiate()
	var gear_rack_instance: Node = gear_rack_scene.instantiate()
	add_child_autofree(ball_rack_instance)
	add_child_autofree(gear_rack_instance)

	assert_not_null(
		ball_rack_instance.get_node_or_null("DropTarget"),
		"ball rack scene should expose a DropTarget child",
	)
	assert_not_null(
		gear_rack_instance.get_node_or_null("DropTarget"),
		"gear rack scene should expose a DropTarget child",
	)
	assert_true(
		ball_rack_instance.get_node("DropTarget") is Area2D,
		"ball rack DropTarget should be an Area2D",
	)
	assert_true(
		gear_rack_instance.get_node("DropTarget") is Area2D,
		"gear rack DropTarget should be an Area2D",
	)


func test_hide_slot_for_hides_only_the_matching_item() -> void:
	# SH-332: rack hides the source slot during a grab so the player sees one body, not two.
	var alpha := _make_item("ball_alpha", &"ball")
	var beta := _make_item("ball_beta", &"ball")
	var manager: Node = _make_manager_with([alpha, beta])
	manager._progression.friendship_point_balance = 10000
	var rack := _make_rack(&"ball", manager)
	manager.take(alpha.key)
	manager.take(beta.key)
	await get_tree().process_frame

	rack.hide_slot_for(alpha.key)

	for child in rack.slot_container.get_children():
		if child is Node2D and String(child.name).begins_with("Slot_"):
			var key: String = child.get_meta(&"item_key", "")
			if key == alpha.key:
				assert_false(child.visible, "grabbed slot is hidden during the gesture")
			elif key == beta.key:
				assert_true(child.visible, "non-grabbed slots stay visible")


func test_reveal_slot_for_restores_visibility() -> void:
	var alpha := _make_item("ball_alpha", &"ball")
	var manager: Node = _make_manager_with([alpha])
	manager._progression.friendship_point_balance = 10000
	var rack := _make_rack(&"ball", manager)
	manager.take(alpha.key)
	await get_tree().process_frame

	rack.hide_slot_for(alpha.key)
	rack.reveal_slot_for(alpha.key)

	for child in rack.slot_container.get_children():
		if child is Node2D and String(child.name).begins_with("Slot_"):
			assert_true(child.visible, "drop_completed reveals the slot again")
