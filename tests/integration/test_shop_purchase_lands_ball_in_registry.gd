## Step 7.7: shop purchases route ball-role items into the BallReconciler registry directly.
## Three destinations are exercised: rack -> STORED, court -> PLAY, venue floor -> OUT_REST.
## Equipment-role purchases keep their existing HeldBody loose-body path (regression).
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _rack: RackDisplay
var _rack_drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController


func _make_rack(manager: Node) -> RackDisplay:
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
	return rack


func _make_area(position: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_def: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var equipment_def: ItemDefinition = ItemFactory.create(
		"gear_alpha", &"paddle_speed", &"add", 10.0
	)
	# Default ItemFactory.create leaves role unset; explicit empty (not ball) routes to the loose-body path.
	equipment_def.role = &""
	# HeldBody.make_for refuses items with no at_rest_shape; equipment needs one for the loose-body lane.
	var gear_shape := CircleShape2D.new()
	gear_shape.radius = 7.2
	equipment_def.at_rest_shape = gear_shape
	var typed_items: Array[ItemDefinition] = [ball_def, equipment_def]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000

	_rack = _make_rack(_manager)
	# Rack drop area at -1000,0 with a 300x200 footprint; comfortably away from court/venue.
	_rack_drop_target = _make_area(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	_reconciler.ball_rack = _rack
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _rack_drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-100, -100), Vector2(200, 200))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)
	await get_tree().process_frame


func _free_any_initial_balls() -> void:
	# _reconcile_stored_kit_items adopts kit balls on first frame; clear them so each AC starts
	# from a known empty registry.
	for key in _manager.get_kit_items(&"ball"):
		var ball: Ball = _reconciler.get_ball_for_key(key)
		if ball != null:
			_reconciler.release_ball(key)
			ball.queue_free()
	await get_tree().process_frame


# --- Ball-role purchase destinations ----------------------------------------------------------


func test_ball_role_purchase_over_rack_lands_in_registry_as_stored() -> void:
	await _free_any_initial_balls()
	# Position lands inside the rack drop area (centered on -1000,0).
	var release_at: Vector2 = Vector2(-1000, 0)
	var spawned: bool = _drag.spawn_purchased_at("ball_alpha", release_at, Vector2.ZERO)
	assert_true(spawned, "rack drop target accepts ball-role purchase")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "purchase over rack adopts a STORED Ball into the registry")
	assert_eq(
		ball.play_state, Ball.PlayState.STORED, "rack-landed purchase enters STORED, not PLAY"
	)


func test_ball_role_purchase_over_court_lands_in_registry_as_play() -> void:
	await _free_any_initial_balls()
	# Centre of the court rect: -100,-100 size 200x200 -> centre at 0,0.
	var release_at: Vector2 = Vector2(0, 0)
	var spawned: bool = _drag.spawn_purchased_at("ball_alpha", release_at, Vector2(120, 0))
	assert_true(spawned, "court drop target accepts ball-role purchase")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "purchase over court spawns a registry Ball")
	var in_play: bool = (
		ball.play_state == Ball.PlayState.PLAY_NORMAL or ball.play_state == Ball.PlayState.PLAY_ARC
	)
	assert_true(in_play, "court-landed purchase enters PLAY (NORMAL or ARC)")


func test_ball_role_purchase_over_venue_floor_lands_in_registry_as_out_rest() -> void:
	await _free_any_initial_balls()
	# Inside venue but outside court and outside the rack drop area: clearly venue-floor.
	var release_at: Vector2 = Vector2(800, 500)
	var spawned: bool = _drag.spawn_purchased_at("ball_alpha", release_at, Vector2(50, 0))
	assert_true(spawned, "venue drop target accepts ball-role purchase")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "purchase over venue floor lifts a registry Ball")
	assert_eq(
		ball.play_state,
		Ball.PlayState.OUT_REST,
		"venue-landed purchase enters OUT_REST, not PLAY or STORED",
	)


# --- Equipment-role regression ---------------------------------------------------------------


func test_equipment_role_purchase_over_venue_still_spawns_held_body() -> void:
	# Equipment retains the legacy HeldBody loose-body lane until a separate equipment-role rework.
	await _free_any_initial_balls()
	var release_at: Vector2 = Vector2(800, 500)
	var spawned: bool = _drag.spawn_purchased_at("gear_alpha", release_at, Vector2.ZERO)
	assert_true(spawned, "venue drop target accepts equipment-role purchase")
	# Find a HeldBody under the reconciler's loose-body host (parent of the loose lane).
	var host: Node = _drag.get_loose_body_host()
	var found: HeldBody = null
	for child in host.get_children():
		if child is HeldBody and (child as HeldBody).item_key == "gear_alpha":
			found = child
			break
	assert_not_null(found, "equipment-role venue purchase still spawns a HeldBody loose body")
	assert_null(
		_reconciler.get_ball_for_key("gear_alpha"),
		"equipment never enters the BallReconciler registry",
	)
