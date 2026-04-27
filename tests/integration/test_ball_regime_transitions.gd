## SH-218 end-to-end ball regime transitions; see designs/01-prototype/21-ball-dynamics.md#regime-unification.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemManagerScript: GDScript = preload("res://scripts/items/item_manager.gd")
const BallScene: PackedScene = preload("res://scenes/ball.tscn")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")

const COURT_BOUNDS: Rect2 = Rect2(Vector2(-600, -400), Vector2(1200, 800))
const VENUE_BOUNDS: Rect2 = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
const RACK_CENTER: Vector2 = Vector2(-1500, 0)
const RACK_SIZE: Vector2 = Vector2(300, 200)

var _manager: Node
var _host: Node2D
var _rack: RackDisplay
var _drop_target: Area2D
var _reconciler: BallReconciler
var _drag: BallDragController
var _storage: SaveStorage


func before_each() -> void:
	_storage = double(SaveStorage).new()
	stub(_storage.write).to_return(true)
	stub(_storage.read).to_return("")

	_manager = ItemManagerScript.new()
	_manager._progression = ProgressionData.new(_storage)
	_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	_manager.items.assign(typed_items)
	_manager._progression.friendship_point_balance = 10000
	add_child_autofree(_manager)

	_host = Node2D.new()
	_host.name = "BallHost"
	add_child_autofree(_host)

	_rack = _build_rack(_manager)

	_drop_target = _build_drop_target(RACK_CENTER, RACK_SIZE)

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager, _host)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = COURT_BOUNDS
	_drag.venue_bounds = VENUE_BOUNDS
	add_child_autofree(_drag)


func _build_rack(manager: Node) -> RackDisplay:
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


func _build_drop_target(center: Vector2, size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = center
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func _permanent_balls() -> Array:
	var result: Array = []
	for child in _host.get_children():
		if child is Ball and not (child as Ball).is_temporary:
			result.append(child)
	return result


func _all_balls_under_host() -> Array:
	var result: Array = []
	for child in _host.get_children():
		if child is Ball:
			result.append(child)
	return result


# --- Scenario 1: rack -> court via drag spawns a Ball in play ---------------


func test_place_ball_drags_onto_court_and_reconciler_spawns_live_ball() -> void:
	_manager.take("training_ball")
	assert_eq(
		_rack.get_displayed_keys(), ["training_ball"], "precondition: rack shows the owned token"
	)
	var base_min: float = _manager.get_stat(&"ball_speed_min")

	_drag.grab_from_rack("training_ball")
	# Drain activation-spawn balls to isolate the release outcome.
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame

	var court_point := Vector2(100, 50)
	var released: bool = _drag.attempt_release(court_point)

	assert_true(released, "release over court should resolve")
	assert_false(_drag.is_dragging(), "held token destroyed on release")
	assert_true(_manager.is_on_court("training_ball"), "placement state settles on court")
	var live: Array = _permanent_balls()
	assert_eq(live.size(), 1, "exactly one Ball for the key after the drop")
	var ball: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(ball, "reconciler tracks the live ball by key")
	assert_eq(ball.global_position, court_point, "ball lands at the release point")
	assert_gt(
		_manager.get_stat(&"ball_speed_min"),
		base_min,
		"ball effect should be registered while the item is on court",
	)
	assert_false(
		"training_ball" in _rack.get_displayed_keys(),
		"rack should hide the token while the ball is on court",
	)


# --- Scenario 2: court -> rack via drag frees the Ball and regrows the token ---


func test_drag_permanent_ball_off_court_onto_rack_regrows_token() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var placed_min: float = _manager.get_stat(&"ball_speed_min")
	assert_true(_manager.is_on_court("training_ball"), "precondition: ball placed")
	assert_not_null(_reconciler.get_ball_for_key("training_ball"), "precondition: live ball exists")

	_drag.grab_live_ball("training_ball")
	await get_tree().process_frame
	var released: bool = _drag.attempt_release(_drop_target.global_position)

	assert_true(released)
	await get_tree().process_frame
	assert_false(
		_manager.is_on_court("training_ball"),
		"rack release should deactivate a permanent ball",
	)
	assert_null(
		_reconciler.get_ball_for_key("training_ball"),
		"reconciler should drop tracking after the ball leaves the court",
	)
	assert_eq(_permanent_balls().size(), 0, "no live Ball instances remain under the host")
	assert_lt(
		_manager.get_stat(&"ball_speed_min"),
		placed_min,
		"effect should deregister once the ball is stored again",
	)
	assert_true(
		"training_ball" in _rack.get_displayed_keys(),
		"rack refresh should regrow the token in its slot",
	)


# --- Scenario 3: rack -> mid-venue release clamps to court edge ------------


func test_drag_ball_onto_mid_venue_position_spawns_at_court_edge() -> void:
	_manager.take("training_ball")
	_drag.grab_from_rack("training_ball")
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame

	# Inside VENUE_BOUNDS.x (-2000..2000) but outside COURT_BOUNDS.x (-600..600).
	var in_venue_outside_court := Vector2(1500, 50)
	var released: bool = _drag.attempt_release(in_venue_outside_court)

	assert_true(released, "release inside venue always resolves")
	assert_true(_manager.is_on_court("training_ball"), "placement should settle on court")
	var live: Array = _permanent_balls()
	assert_eq(live.size(), 1, "exactly one permanent Ball for the key")
	var ball: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(ball)
	var court_right_edge: float = COURT_BOUNDS.position.x + COURT_BOUNDS.size.x
	assert_eq(
		ball.global_position.x,
		court_right_edge,
		"x should clamp to the court's right edge",
	)
	assert_eq(ball.global_position.y, 50.0, "in-bounds y should pass through unchanged")


# --- Scenario 4: temporary balls live outside the reconciler's set ---------


# todo: SH-224 drive the spawn through SpawnBallOutcome once it lands
func test_temporary_ball_does_not_touch_placement_or_reconciler() -> void:
	assert_false(_manager.is_on_court("training_ball"))
	var base_min: float = _manager.get_stat(&"ball_speed_min")

	var temp: Ball = BallScene.instantiate()
	temp.is_temporary = true
	_host.add_child(temp)
	temp.global_position = Vector2(100, 50)
	await get_tree().process_frame

	assert_eq(
		_permanent_balls().size(),
		0,
		"temporary ball must not appear in the permanent-balls view",
	)
	assert_eq(_all_balls_under_host().size(), 1, "the temporary Ball is parented under the host")
	assert_null(
		_reconciler.get_ball_for_key("training_ball"),
		"reconciler must not track temporary balls against the item key",
	)
	assert_false(
		_manager.is_on_court("training_ball"),
		"temporary spawn must not mark the item as placed",
	)
	assert_almost_eq(
		_manager.get_stat(&"ball_speed_min"),
		base_min,
		0.01,
		"temporary ball has no item-level placement, so no extra effect registers",
	)

	_drag.grab_live_ball("training_ball", true)
	assert_true(_drag.is_dragging(), "temporary drag starts the held-token gesture")

	var released: bool = _drag.attempt_release(Vector2(0, 0))

	assert_true(released)
	assert_false(_drag.is_dragging(), "temporary release clears the drag state")
	assert_null(
		_reconciler.get_ball_for_key("training_ball"),
		"temporary release does not spawn through the reconciler",
	)
	assert_false(
		_manager.is_on_court("training_ball"),
		"temporary release does not flip placement state",
	)


# --- Scenario 5: release from outside venue still lands on the court -------


func test_release_from_far_outside_cursor_spawns_ball_at_court_corner() -> void:
	_manager.take("training_ball")
	_drag.grab_from_rack("training_ball")
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame

	var far_outside := Vector2(99999, 99999)
	var released: bool = _drag.attempt_release(far_outside)

	assert_true(released, "release always resolves, even from a far-outside cursor")
	assert_true(
		_manager.is_on_court("training_ball"),
		"placement settles on court despite the out-of-bounds cursor",
	)
	var ball: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(ball, "release still spawns a live ball")
	var court_max: Vector2 = COURT_BOUNDS.position + COURT_BOUNDS.size
	assert_eq(
		ball.global_position,
		court_max,
		"ball lands at the court corner after the out-of-bounds release",
	)


# --- Scenario 6: save round-trip preserves live ball placement -------------


func test_save_round_trip_preserves_live_ball_placement() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var placed_min: float = _manager.get_stat(&"ball_speed_min")
	assert_not_null(_reconciler.get_ball_for_key("training_ball"), "precondition: live ball exists")

	var saved_blob: String = JSON.stringify(_manager._progression.to_dict())

	var reload_storage: SaveStorage = double(SaveStorage).new()
	stub(reload_storage.write).to_return(true)
	stub(reload_storage.read).to_return(saved_blob)

	var reloaded_manager: Node = ItemManagerScript.new()
	reloaded_manager._progression = ProgressionData.new(reload_storage)
	assert_true(reloaded_manager._progression.load_from_disk(), "reload must parse the saved blob")
	reloaded_manager._effect_manager = EffectManager.new()
	var typed_items: Array[ItemDefinition] = [TrainingBall]
	reloaded_manager.items.assign(typed_items)
	add_child_autofree(reloaded_manager)

	var reloaded_host := Node2D.new()
	reloaded_host.name = "ReloadedBallHost"
	add_child_autofree(reloaded_host)

	var reloaded_reconciler: BallReconciler = BallReconcilerScript.new()
	reloaded_reconciler.configure(reloaded_manager, reloaded_host)
	reloaded_reconciler.spawn_for_existing_on_load = true
	add_child_autofree(reloaded_reconciler)
	await get_tree().process_frame

	assert_true(
		reloaded_manager.is_on_court("training_ball"),
		"placement must survive the save/reload cycle",
	)
	var reloaded_ball: Ball = reloaded_reconciler.get_ball_for_key("training_ball")
	assert_not_null(reloaded_ball, "reconciler re-spawned the ball from progression on load")
	assert_true(
		reloaded_ball.get_parent() == reloaded_host,
		"the live ball is parented under the reloaded host",
	)
	assert_almost_eq(
		reloaded_manager.get_stat(&"ball_speed_min"),
		placed_min,
		0.01,
		"reloaded ball item must run the same effect as before the save",
	)


# --- Scenario 7 (SH-245): press-drag-release on rack drives full input pipeline -


func test_real_press_drag_release_on_rack_spawns_live_ball_with_item_art() -> void:
	# Drives the actual InputEventMouseButton path on the rack token: press,
	# move, release. Asserts the released live ball lands at the release position
	# AND wears the item's authored art (SH-244).
	_manager.take("training_ball")
	await get_tree().process_frame
	var displayed: Array[String] = _rack.get_displayed_keys()
	assert_eq(displayed, ["training_ball"], "precondition: rack shows the token")

	# Resolve the slot's click area and feed it a mouse-down event.
	var slot: Node2D = _find_slot_for_key("training_ball")
	assert_not_null(slot, "rack slot exists for the owned key")
	var click_area: Area2D = slot.get_node("ClickArea")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	click_area.input_event.emit(get_viewport(), press, 0)

	assert_true(_drag.is_dragging(), "press on the rack token starts the held-token gesture")
	assert_false(
		_manager.is_on_court("training_ball"),
		"press alone must not introduce the ball (SH-245)",
	)

	# Simulate cursor motion across a window so release velocity is non-zero.
	_drag._cursor_samples.clear()
	_drag._cursor_samples.append({"time": 0.0, "position": Vector2.ZERO})
	_drag._cursor_samples.append({"time": 0.04, "position": Vector2(200, 0)})

	# Release over the court. Drive the actual mouse-button-up path through _input.
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	_drag._input(release)

	assert_false(_drag.is_dragging(), "release ends the gesture")
	assert_true(_manager.is_on_court("training_ball"), "release over court activates the item")
	var ball: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(ball, "reconciler should own the live ball after release")
	assert_true(ball.has_item_art(), "live ball must render the item's authored art (SH-244)")


# --- Scenario 8 (SH-247): real press on a live Ball flips into mid-rally grab --


func test_real_press_on_live_ball_starts_mid_rally_grab_and_release_reinstates() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var live: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(live, "precondition: live ball exists")
	assert_true(live.input_pickable, "live ball must be input_pickable so a press routes through")

	# Drive a real press through the Ball's input_event signal.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	live.input_event.emit(get_viewport(), press, 0)

	assert_true(_drag.is_dragging(), "press on a live ball flips into drag mode (SH-247)")
	await get_tree().process_frame
	assert_false(
		is_instance_valid(live),
		"the live ball is freed during the hold; held token takes over the cursor",
	)

	# Release over the court reinstates a live ball at the cursor.
	var court_point := Vector2(50, -25)
	var released: bool = _drag.attempt_release(court_point)
	assert_true(released)

	var reinstated: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(reinstated, "court release should reinstate a Ball via the reconciler")
	assert_eq(reinstated.global_position, court_point)
	assert_true(reinstated.has_item_art(), "reinstated ball preserves the item's art (SH-244)")


# --- Scenario 9 (SH-262): pre-existing scene Ball is grabbable mid-rally ----


# The live court scene ships with a Ball node already in the tree (see scenes/court.tscn).
# That ball never went through ensure_ball_for_key, so the reconciler never emitted
# ball_spawned for it, so the drag controller never wired its `pressed` signal. Players
# pressed mid-rally and nothing happened. Reproduce by parenting a fresh Ball under the
# host BEFORE the reconciler ever spawns one, then drive a real press through it.
func test_pre_existing_court_ball_is_grabbable_mid_rally() -> void:
	# Mirror the scene-load shape: Ball is already a child of the host with its authored item_key
	# (court.tscn sets training_ball), reconciler never invoked ensure_ball_for_key for this instance.
	_manager.take("training_ball")
	var pre_existing: Ball = BallScene.instantiate()
	pre_existing.item_key = "training_ball"
	_host.add_child(pre_existing)
	pre_existing.global_position = Vector2(0, 0)
	await get_tree().process_frame
	# Allow any deferred adoption pass to run before we drive input.
	await get_tree().process_frame

	assert_eq(_permanent_balls().size(), 1, "precondition: pre-existing Ball lives under host")
	assert_true(
		pre_existing.input_pickable, "Ball must be input_pickable for press to route through"
	)
	assert_false(_drag.is_dragging(), "precondition: no drag in progress before the press")

	# Drive a real press on the pre-existing Ball.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	pre_existing.input_event.emit(get_viewport(), press, 0)

	assert_true(
		_drag.is_dragging(),
		"pressing a pre-existing scene Ball must flip the drag controller into mid-rally grab (SH-262)",
	)
	await get_tree().process_frame
	assert_false(
		is_instance_valid(pre_existing),
		"the pre-existing ball is freed during the hold; held token takes over the cursor",
	)


func _find_slot_for_key(item_key: String) -> Node2D:
	for child in _rack.slot_container.get_children():
		if child is Node2D and child.get_meta(&"item_key", "") == item_key:
			return child
	return null
