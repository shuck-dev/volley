## SH-569 Ball Kit: verifies ItemDragController's screen-space Kit path alongside the existing
## world-space drop_targets pipeline (court/venue).
extends GutTest

const ItemDragControllerScript: GDScript = preload("res://scripts/items/item_drag_controller.gd")

var _drag: ItemDragController
var _kit: BallKit


func before_each() -> void:
	BallTestHelpers.use_autoloads(self, [BallTestHelpers.make_ball_item("ball_alpha")])

	_kit = BallTestHelpers.make_kit(BallManager, self, 1)
	await get_tree().process_frame

	_drag = ItemDragControllerScript.new()
	add_child_autofree(_drag)
	_kit.connect_drag_controller(_drag)

	BallTestHelpers.make_drop_targets(self)


func after_each() -> void:
	await get_tree().process_frame


func _kit_slot_screen_position() -> Vector2:
	var slot: KitSlot = _kit.slot_container.get_child(0)
	return slot.get_global_rect().get_center()


func _grab_live(ball_key: String) -> void:
	BallTracker.bring_into_play(ball_key, Vector2.ZERO, Vector2(200, 0))
	assert_true(_drag.grab(ball_key))


func test_releasing_over_a_kit_slot_moves_the_ball_into_the_kit() -> void:
	var key: String = BallManager.take("ball_alpha")
	_grab_live(key)

	var accepted: bool = _drag.attempt_release(Vector2(9999, 9999), _kit_slot_screen_position())

	assert_true(accepted, "a release over a Kit slot should be accepted")
	assert_eq(BallManager.get_placement(key), Placement.IN_KIT)


func test_kit_slot_hit_takes_priority_over_an_overlapping_world_drop_target() -> void:
	var key: String = BallManager.take("ball_alpha")
	_grab_live(key)

	# The venue drop target also covers this point; the screen-space Kit hit must win.
	var accepted: bool = _drag.attempt_release(Vector2(-1500, 0), _kit_slot_screen_position())

	assert_true(accepted)
	assert_eq(BallManager.get_placement(key), Placement.IN_KIT)


func test_release_over_venue_leaves_the_ball_loose() -> void:
	var key: String = BallManager.take("ball_alpha")
	_grab_live(key)

	var accepted: bool = _drag.attempt_release(Vector2(-1500, 0), Vector2(-99999, -99999))

	assert_true(accepted, "the release lands loose in the venue when Kit is not hit")
	assert_true(BallManager.is_loose_in_venue(key))


func test_kit_release_denied_everywhere_keeps_the_ball_in_the_kit() -> void:
	var key: String = BallManager.take("ball_alpha")
	BallManager.add_to_kit(key, 0)
	assert_true(_drag.grab(key))

	var accepted: bool = _drag.attempt_release(Vector2(-999999, -999999), Vector2(-999999, -999999))

	assert_false(accepted, "no target anywhere accepts this release")
	assert_eq(
		BallManager.get_placement(key),
		Placement.IN_KIT,
		"a denied release must not mutate placement away from the Kit",
	)
	assert_null(
		BallTracker.get_ball_for_key(key),
		"no ghost ball should be spawned for a still-kitted item",
	)


func test_full_kit_rejects_a_different_ball_and_falls_through() -> void:
	var alpha: BallDefinition = BallTestHelpers.make_ball_item("ball_alpha")
	var beta: BallDefinition = BallTestHelpers.make_ball_item("ball_beta")
	BallManager.items.assign([alpha, beta] as Array[BallDefinition])
	var alpha_key: String = BallManager.take("ball_alpha")
	var beta_key: String = BallManager.take("ball_beta")
	BallManager.add_to_kit(alpha_key, 0)
	assert_eq(BallManager.get_kit_items().size(), 1, "precondition: the single Kit slot is full")

	_grab_live(beta_key)

	var accepted: bool = _drag.attempt_release(Vector2(-1500, 0), _kit_slot_screen_position())

	assert_true(
		accepted,
		"the Kit rejects the swap and the release falls through to the venue",
	)
	assert_true(
		BallManager.is_loose_in_venue(beta_key),
		"a full Kit slot must reject a different ball rather than swap it in",
	)
