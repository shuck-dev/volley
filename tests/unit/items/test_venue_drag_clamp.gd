extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")


func _make_drag() -> ItemDragController:
	var drag: ItemDragController = ItemDragControllerScript.new()
	add_child_autofree(drag)
	return drag


func _make_bound_node(x: float) -> Node2D:
	var marker := Node2D.new()
	marker.global_position = Vector2(x, 0)
	add_child_autofree(marker)
	return marker


func test_clamp_derives_x_from_venue_bound_nodes() -> void:
	var drag: ItemDragController = _make_drag()
	drag.venue_left_bound = _make_bound_node(-1700)
	drag.venue_right_bound = _make_bound_node(1920)
	drag.venue_ceiling = _make_bound_node(0)
	drag.venue_floor = _make_bound_node(0)
	drag.venue_ceiling.global_position.y = -1500
	drag.venue_floor.global_position.y = 410
	drag._derive_venue_bounds_from_nodes()

	var left_clamped: Vector2 = drag._clamp_to_venue(Vector2(-9999, 0))
	var right_clamped: Vector2 = drag._clamp_to_venue(Vector2(9999, 0))

	assert_eq(left_clamped.x, -1700.0, "left clamp must use venue_left_bound x, not a literal")
	assert_eq(right_clamped.x, 1920.0, "right clamp must use venue_right_bound x, not a literal")


func test_clamp_does_not_stop_short_of_real_venue_at_left_edge() -> void:
	var drag: ItemDragController = _make_drag()
	drag.venue_left_bound = _make_bound_node(-1700)
	drag.venue_right_bound = _make_bound_node(1920)
	drag.venue_ceiling = _make_bound_node(0)
	drag.venue_floor = _make_bound_node(0)
	drag.venue_ceiling.global_position.y = -1500
	drag.venue_floor.global_position.y = 410
	drag._derive_venue_bounds_from_nodes()

	var at_short_clamp: Vector2 = drag._clamp_to_venue(Vector2(-1300, 0))

	assert_eq(
		at_short_clamp.x,
		-1300.0,
		"x=-1300 is inside the real venue; old literal clamp (-1200 left) would have truncated it",
	)


func test_clamp_preserves_identity_when_no_bound_nodes_wired() -> void:
	var drag: ItemDragController = _make_drag()

	var point := Vector2(99999, -99999)
	var result: Vector2 = drag._clamp_to_venue(point)

	assert_eq(result, point, "unset bound nodes leave the clamp as a pass-through")


func test_venue_bounds_updates_when_bound_nodes_change_position() -> void:
	var drag: ItemDragController = _make_drag()
	var left: Node2D = _make_bound_node(-1700)
	var right: Node2D = _make_bound_node(1920)
	drag.venue_left_bound = left
	drag.venue_right_bound = right
	drag.venue_ceiling = _make_bound_node(-1500)
	drag.venue_floor = _make_bound_node(410)
	drag._derive_venue_bounds_from_nodes()

	left.global_position.x = -2000
	right.global_position.x = 2100
	drag._derive_venue_bounds_from_nodes()

	var far_left: Vector2 = drag._clamp_to_venue(Vector2(-9999, 0))
	var far_right: Vector2 = drag._clamp_to_venue(Vector2(9999, 0))

	assert_eq(far_left.x, -2000.0, "re-derived clamp reflects updated left bound position")
	assert_eq(far_right.x, 2100.0, "re-derived clamp reflects updated right bound position")
