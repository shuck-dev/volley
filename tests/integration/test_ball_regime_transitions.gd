## SH-218 integration: end-to-end ball regime transitions across drag, reconciler, item manager, rack.
##
## Drives the full chain through public surfaces (grab_from_rack, grab_live_ball, attempt_release,
## activate/deactivate, save round-trip). No mocks beyond SaveStorage for the progression disk layer.
## Asserts on externally observable outcomes: Ball instances under the host, placement state on
## ItemManager, rack-display occupancy, effect registration (via get_stat), and save-persisted state.
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


# The player owns a ball token on the rack. They grab it and release over the court.
# The full chain fires: drag activates the item, ItemManager emits court_changed, the
# reconciler spawns a real Ball, and the rack stops showing the token.
func test_place_ball_drags_onto_court_and_reconciler_spawns_live_ball() -> void:
	_manager.take("training_ball")
	assert_eq(
		_rack.get_displayed_keys(), ["training_ball"], "precondition: rack shows the owned token"
	)
	var base_min: float = _manager.get_stat(&"ball_speed_min")

	_drag.grab_from_rack("training_ball")
	# grab_from_rack already activates the item, which fires the reconciler on
	# court_changed. Drain any spawned-on-activation balls before asserting the
	# drop path: this scenario asserts the release outcome, not the activation-spawn.
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


# Start with a placed permanent ball. The player grabs it mid-rally and drops it
# over the rack DropTarget. The live Ball is freed, placement flips to stored,
# the effect stops running, and the rack's refresh puts the token back.
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


# Releasing inside venue_bounds but outside court_bounds should still spawn a
# ball: the release rule clamps the spawn position to the nearest valid court
# point rather than no-opping.
func test_drag_ball_onto_mid_venue_position_spawns_at_court_edge() -> void:
	_manager.take("training_ball")
	_drag.grab_from_rack("training_ball")
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame

	# Inside VENUE_BOUNDS.x span (-2000..2000) but outside COURT_BOUNDS.x span (-600..600).
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


# A temporary ball (future SpawnBallOutcome) is instantiated directly, tagged
# is_temporary, and parented under the host. It does not touch on_court,
# does not show up to the reconciler, and can be dragged without affecting
# the permanent-placement bookkeeping.
func test_temporary_ball_does_not_touch_placement_or_reconciler() -> void:
	# Baseline: no placement, no live ball, no effects.
	assert_false(_manager.is_on_court("training_ball"))
	var base_min: float = _manager.get_stat(&"ball_speed_min")

	var temp: Ball = BallScene.instantiate()
	temp.is_temporary = true
	_host.add_child(temp)
	temp.global_position = Vector2(100, 50)
	await get_tree().process_frame

	# Permanent-ball bookkeeping is untouched.
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

	# The drag path for a temporary ball still releases cleanly and does not
	# spawn a permanent ball through the reconciler.
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


# --- Scenario 5: follow clamps to venue; release resolves to court clamp ---


# The cursor can range arbitrarily far, but the held-token follow clamps to
# venue bounds each frame. A release from a far-outside position therefore
# fires from the clamped-to-venue point, which further clamps to court bounds
# for the spawn.
func test_release_from_outside_venue_clamps_to_venue_then_court() -> void:
	_manager.take("training_ball")
	_drag.grab_from_rack("training_ball")
	for ball in _all_balls_under_host():
		ball.queue_free()
	await get_tree().process_frame

	var far_outside := Vector2(99999, 99999)
	# Follow clamp: a position beyond venue bounds is pulled back to the rect corner.
	var follow_clamp: Vector2 = _drag._clamp_to_venue(far_outside)
	var venue_max: Vector2 = VENUE_BOUNDS.position + VENUE_BOUNDS.size
	assert_eq(follow_clamp, venue_max, "held-token follow clamps to venue rect corner")

	# Release always fires (per the unified always-fires rule) and lands on the
	# court-clamped position; venue corner (2000, 1200) clamps to court corner (600, 400).
	var released: bool = _drag.attempt_release(far_outside)
	assert_true(released, "release always resolves, even from a far-outside cursor")
	var ball: Ball = _reconciler.get_ball_for_key("training_ball")
	assert_not_null(ball, "release still spawns a live ball")
	var court_max: Vector2 = COURT_BOUNDS.position + COURT_BOUNDS.size
	assert_eq(
		ball.global_position,
		court_max,
		"ball lands at the court-clamped corner after the follow->release chain",
	)


# --- Scenario 6: save round-trip preserves live ball placement -------------


# A placed permanent ball should survive a save/reload: after reloading
# progression into a fresh ItemManager + reconciler, the ball reappears,
# placement is preserved, and the reconciler is tracking it.
func test_save_round_trip_preserves_live_ball_placement() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var placed_min: float = _manager.get_stat(&"ball_speed_min")
	assert_not_null(_reconciler.get_ball_for_key("training_ball"), "precondition: live ball exists")

	# Round-trip through a stringified progression blob.
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

	# Placement survived the round-trip.
	assert_true(
		reloaded_manager.is_on_court("training_ball"),
		"placement must survive the save/reload cycle",
	)
	# Reconciler reflects the live state: the tracked ball is in the host tree.
	var reloaded_ball: Ball = reloaded_reconciler.get_ball_for_key("training_ball")
	assert_not_null(reloaded_ball, "reconciler re-spawned the ball from progression on load")
	assert_true(
		reloaded_ball.get_parent() == reloaded_host,
		"the live ball is parented under the reloaded host",
	)
	# Effects match: reloaded stats must reflect the placed ball.
	assert_almost_eq(
		reloaded_manager.get_stat(&"ball_speed_min"),
		placed_min,
		0.01,
		"reloaded ball item must run the same effect as before the save",
	)
