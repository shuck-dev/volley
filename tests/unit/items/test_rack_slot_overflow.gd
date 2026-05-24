## #679: rack must not stack stored balls into the same slot.
extends GutTest

const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")


func _make_rack(manager: Node, marker_count: int) -> RackDisplay:
	var rack: RackDisplay = RackDisplayScript.new()
	rack.role = &"ball"

	var slot_container := Node2D.new()
	slot_container.name = "SlotContainer"
	rack.add_child(slot_container)

	for index in marker_count:
		var marker := Node2D.new()
		marker.name = "SlotMarker%d" % index
		marker.position = Vector2(index * 32, 0)
		slot_container.add_child(marker)

	rack.slot_container = slot_container
	rack.configure(manager)
	add_child_autofree(rack)
	return rack


func _seed_manager(ball_keys: Array[String]) -> Node:
	var manager: Node = ItemFactory.create_manager(self)
	var typed_items: Array[ItemDefinition] = []
	for key in ball_keys:
		typed_items.append(ItemTestHelpersScript.make_ball_item(key))
	manager.items.assign(typed_items)
	manager.economy.friendship_point_balance = 100000
	return manager


func test_every_stored_ball_lands_at_a_distinct_slot_position() -> void:
	var keys: Array[String] = ["ball_a", "ball_b", "ball_c", "ball_d"]
	var manager: Node = _seed_manager(keys)
	var rack: RackDisplay = _make_rack(manager, 8)

	var reconciler: BallReconciler = BallReconcilerScript.new()
	reconciler.configure(manager)
	reconciler.ball_rack = rack
	add_child_autofree(reconciler)

	for key in keys:
		manager.take(key)
	await get_tree().process_frame

	var seen_positions: Array[Vector2] = []
	for key in keys:
		var ball: Ball = reconciler.get_ball_for_key(key)
		assert_not_null(ball, "stored ball spawned for %s" % key)
		assert_false(
			seen_positions.has(ball.global_position),
			"ball %s at %s collides with an earlier slot" % [key, ball.global_position]
		)
		seen_positions.append(ball.global_position)


func test_distinct_keys_resolve_to_distinct_marker_positions() -> void:
	var keys: Array[String] = ["ball_a", "ball_b", "ball_c", "ball_d"]
	var manager: Node = _seed_manager(keys)
	var rack: RackDisplay = _make_rack(manager, 8)
	for key in keys:
		manager.take(key)

	var positions: Array[Vector2] = []
	for key in keys:
		var slot_position: Vector2 = rack.get_slot_position_for(key)
		assert_false(
			positions.has(slot_position),
			"slot lookup for %s collides with an earlier key at %s" % [key, slot_position]
		)
		positions.append(slot_position)
