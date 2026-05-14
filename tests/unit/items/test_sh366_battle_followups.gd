## SH-366 Battle follow-ups: OUT_REST cancel, court→venue ItemManager sync, item_key on spawn, loose-clear on restore.
extends GutTest

const BallDragControllerScript: GDScript = preload("res://scripts/items/ball_drag_controller.gd")
const BallReconcilerScript: GDScript = preload("res://scripts/items/ball_reconciler.gd")
const RackDisplayScript: GDScript = preload("res://scripts/items/rack_display.gd")
const ItemTestHelpersScript: GDScript = preload("res://tests/helpers/item_test_helpers.gd")

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
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


func _make_drop_target(area_position: Vector2, area_size: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = area_position
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = area_size
	collision.shape = rectangle
	area.add_child(collision)
	add_child_autofree(area)
	return area


func before_each() -> void:
	_manager = ItemFactory.create_manager(self)
	var ball_alpha: ItemDefinition = ItemTestHelpersScript.make_ball_item("ball_alpha")
	var typed_items: Array[ItemDefinition] = [ball_alpha]
	_manager.items.assign(typed_items)
	_manager.economy.friendship_point_balance = 10000

	_rack = _make_rack(_manager)
	_drop_target = _make_drop_target(Vector2(-1000, 0), Vector2(300, 200))

	_reconciler = BallReconcilerScript.new()
	_reconciler.configure(_manager)
	add_child_autofree(_reconciler)

	_drag = BallDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _reconciler)
	_drag.court_bounds = Rect2(Vector2(-600, -400), Vector2(1200, 800))
	_drag.venue_bounds = Rect2(Vector2(-2000, -1200), Vector2(4000, 2400))
	add_child_autofree(_drag)


# --- Finding 1: OUT_REST live-grab cancel unfreezes back to OUT_REST instead of stuck OUT_HELD --


func test_out_rest_live_grab_cancel_returns_to_out_rest() -> void:
	_manager.take("ball_alpha")
	# Drive the ball into OUT_REST at a venue-floor position via the documented release path.
	_manager.activate("ball_alpha")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	assert_not_null(ball, "precondition: live ball exists on court")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame
	# Release inside venue but outside court → ball ends in OUT_REST and ItemManager flips loose-in-venue.
	assert_true(_drag.attempt_release(Vector2(1500, 50)))
	assert_eq(ball.play_state, Ball.PlayState.OUT_REST)
	assert_true(_manager.is_loose_in_venue("ball_alpha"))

	# Grab the OUT_REST ball.
	assert_true(_drag.grab_live_ball("ball_alpha", false))
	assert_eq(ball.play_state, Ball.PlayState.OUT_HELD)
	# OUT_REST origin: the ball was not on court at grab time.
	assert_false(_drag._held_was_on_court, "OUT_REST grab must not flag was_on_court")

	# Trigger cancel-to-source via the expansion timeout.
	_drag._gesture_below_threshold = false
	_drag._mouse_button_down = false
	_drag._expansion_started_at = (
		float(Time.get_ticks_msec()) / 1000.0 - _drag.expansion_ring_hold_s * 2.0 - 0.1
	)
	_drag._update_expansion_state(Vector2(99999, 99999))

	assert_false(_drag.is_dragging(), "cancel completes the gesture")
	assert_eq(
		ball.play_state,
		Ball.PlayState.OUT_REST,
		"OUT_REST origin restores to OUT_REST, not stuck OUT_HELD"
	)
	assert_false(ball.freeze, "OUT_REST unfreezes so gravity integrates")


# --- Finding 3: live-court → venue release marks loose-in-venue so save reload skips court-spawn --


func test_live_court_to_venue_release_marks_loose_in_venue() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	assert_true(_manager.is_on_court("ball_alpha"), "precondition: ball is on court")

	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame

	# Release inside venue but outside court bounds.
	assert_true(_drag.attempt_release(Vector2(1500, 50)))

	assert_true(
		_manager.is_loose_in_venue("ball_alpha"),
		"live court→venue release flips the loose-in-venue overlay",
	)
	assert_false(
		_manager.is_on_court("ball_alpha"),
		"is_on_court returns false once loose-in-venue overlay is set",
	)
	assert_eq(
		_manager.get_court_items().size(),
		0,
		"get_court_items skips the venue-floor ball so save reload does not respawn at the floor",
	)


# --- Finding 4: reconciler-spawned balls carry item_key for downstream lookups --


func test_release_into_rest_sets_ball_item_key() -> void:
	var ball: Ball = _reconciler.release_into_rest("ball_alpha", Vector2(100, 50), Vector2.ZERO)
	assert_eq(ball.item_key, "ball_alpha")


func test_adopt_stored_sets_ball_item_key() -> void:
	var ball: Ball = _reconciler.adopt_stored("ball_alpha", Vector2(40, 0))
	assert_eq(ball.item_key, "ball_alpha")


func test_ensure_ball_for_key_sets_ball_item_key() -> void:
	var ball: Ball = _reconciler.ensure_ball_for_key("ball_alpha", Vector2(0, 0), Vector2.ZERO)
	assert_eq(ball.item_key, "ball_alpha")


# --- Finding 5: restoring a held ball to STORED clears loose-in-venue overlay --


func test_restore_held_ball_to_stored_clears_loose_in_venue() -> void:
	_manager.take("ball_alpha")
	_manager.activate("ball_alpha")
	var ball: Ball = _reconciler.get_ball_for_key("ball_alpha")
	_drag.grab_live_ball("ball_alpha", false)
	await get_tree().process_frame
	# Drop on the venue floor to set loose-in-venue.
	assert_true(_drag.attempt_release(Vector2(1500, 50)))
	assert_true(_manager.is_loose_in_venue("ball_alpha"))

	# Re-grab the OUT_REST ball, then restore to STORED via the rack-release safety net.
	_drag.grab_live_ball("ball_alpha", false)
	_drag._restore_held_ball_to_stored("ball_alpha")

	assert_false(
		_manager.is_loose_in_venue("ball_alpha"),
		"restore-to-stored must clear the overlay so the rack slot reveals",
	)
	assert_eq(ball.play_state, Ball.PlayState.STORED)
