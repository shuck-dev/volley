## SH-569 Ball Kit: verifies ItemDragController's screen-space Kit path alongside the existing
## world-space drop_targets pipeline (rack/court/venue), which stays unaffected.
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")
const BallTrackerScript: GDScript = preload("res://scripts/items/ball_tracker.gd")

var _manager: Node
var _rack: RackDisplay
var _drop_target: Area2D
var _ball_tracker: Node
var _drag: ItemDragController
var _kit: BallKit


func before_each() -> void:
	_manager = BallFactory.create_manager(self)
	_manager.items.assign([BallTestHelpers.make_ball_item("ball_alpha")] as Array[BallDefinition])
	_manager.economy.soul_balance = 10000

	_rack = BallTestHelpers.make_rack(_manager, self)
	_drop_target = BallTestHelpers.make_drop_area(Vector2(-1500, 0), Vector2(300, 200), self)

	_ball_tracker = BallTrackerScript.new()
	_ball_tracker.configure(_manager)
	_ball_tracker.ball_rack = _rack
	add_child_autofree(_ball_tracker)

	_kit = BallTestHelpers.make_kit(_manager, self, 1)
	await get_tree().process_frame

	_drag = ItemDragControllerScript.new()
	_drag.configure(_manager, _rack, _drop_target, _ball_tracker)
	_drag.kit = _kit
	_drag.connect_kit()
	add_child_autofree(_drag)

	BallTestHelpers.make_drop_targets(_manager, _ball_tracker, _drop_target.position, self)


func after_each() -> void:
	await get_tree().process_frame


func _kit_slot_screen_position() -> Vector2:
	var slot: KitSlot = _kit.slot_container.get_child(0)
	return slot.get_global_rect().get_center()


func test_releasing_over_a_kit_slot_moves_the_ball_into_the_kit() -> void:
	_manager.take("ball_alpha")
	_manager.deactivate("ball_alpha_1")
	assert_true(_drag.grab_from_rack("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(Vector2(9999, 9999), _kit_slot_screen_position())

	assert_true(accepted, "a release over a Kit slot should be accepted")
	assert_eq(_manager.get_placement("ball_alpha_1"), Placement.IN_KIT)


func test_kit_slot_hit_takes_priority_over_an_overlapping_world_drop_target() -> void:
	_manager.take("ball_alpha")
	_manager.deactivate("ball_alpha_1")
	assert_true(_drag.grab_from_rack("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	# The rack's own DropTarget accepts here too; the screen-space Kit hit must win.
	var accepted: bool = _drag.attempt_release(_drop_target.position, _kit_slot_screen_position())

	assert_true(accepted)
	assert_eq(_manager.get_placement("ball_alpha_1"), Placement.IN_KIT)


func test_release_falls_through_past_the_disabled_rack_to_the_venue() -> void:
	_manager.take("ball_alpha")
	_manager.deactivate("ball_alpha_1")
	assert_true(_drag.grab_from_rack("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(_drop_target.position, Vector2(-99999, -99999))

	assert_true(accepted, "the release falls through to the venue when Kit is not hit")
	assert_true(_manager.is_loose_in_venue("ball_alpha_1"))


func test_kit_release_denied_everywhere_keeps_the_ball_in_the_kit() -> void:
	_manager.take("ball_alpha")
	_manager.add_to_kit("ball_alpha_1", 0)
	assert_true(_drag.grab_from_kit("ball_alpha_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(Vector2(-999999, -999999), Vector2(-999999, -999999))

	assert_false(accepted, "no target anywhere accepts this release")
	assert_eq(
		_manager.get_placement("ball_alpha_1"),
		Placement.IN_KIT,
		"a denied release must not mutate placement away from the Kit",
	)
	assert_null(
		_ball_tracker.get_ball_for_key("ball_alpha_1"),
		"no ghost ball should be spawned for a still-kitted item",
	)


func test_full_kit_rejects_a_different_ball_and_falls_through() -> void:
	var alpha: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	var beta: BallDefinition = BallTestHelpers.make_ball_item("ball_beta")
	_manager.items.assign([alpha, beta] as Array[BallDefinition])
	_manager.take("ball_alpha")
	_manager.take("ball_beta")
	_manager.deactivate("ball_beta_1")
	_manager.add_to_kit("ball_alpha_1", 0)
	assert_eq(_manager.get_kit_items().size(), 1, "precondition: the single Kit slot is full")

	assert_true(_drag.grab_from_rack("ball_beta_1"))
	_drag._gesture_below_threshold = false

	var accepted: bool = _drag.attempt_release(_drop_target.position, _kit_slot_screen_position())

	assert_true(
		accepted,
		"the Kit rejects the swap and the release falls through to the venue behind the disabled rack",
	)
	assert_true(
		_manager.is_loose_in_venue("ball_beta_1"),
		"a full Kit slot must reject a different ball rather than swap it in",
	)
