extends GutTest

# Integration: placement drives effects.
#
# Rule: an item's effects run only while it is physically on the player
# (equipment) or on the court (balls). Racks are inert. Placement is the
# only active/inactive signal — there is no separate flag.
#
# Scenarios cover the full lifecycle through the ItemManager public API:
# activate/deactivate (driven by drag-and-drop in production), level
# changes while placed, and save/reload round-trips.
#
# Fails first against current ItemManager: activate/deactivate, is_on_court,
# get_court_items, and placement persistence are the surfaces SH-96 introduces.

const GripTape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
const TrainingBall: ItemDefinition = preload("res://resources/items/training_ball.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")

var _manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager._progression = ProgressionData.new(_mock_storage)
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([GripTape, TrainingBall, AnkleWeights])
	_manager._progression.friendship_point_balance = 100000
	add_child_autofree(_manager)


# --- Equipment lifecycle ---------------------------------------------------


# Taking an equipment item owns it but leaves it on the rack; no effect runs
# until the player drags it onto their character. Dragging it back to the
# rack stops the effect. Dragging it back on resumes it.
func test_equipment_lifecycle_rack_player_rack_player() -> void:
	var base_size: float = _manager.get_stat(&"paddle_size")

	# Take-only: owned, sitting on the gear rack. No effect.
	_manager.take("grip_tape")
	assert_almost_eq(
		_manager.get_stat(&"paddle_size"),
		base_size,
		0.01,
		"rack-resident equipment must not affect stats",
	)
	assert_false(_manager.is_on_court("grip_tape"), "take() should not place on player")

	# Placed on player → effect runs.
	assert_true(_manager.activate("grip_tape"), "activate should accept an owned equipment item")
	var placed_size: float = _manager.get_stat(&"paddle_size")
	assert_gt(placed_size, base_size, "equipment on player should register its effect")

	# Moved back to rack → effect stops.
	assert_true(_manager.deactivate("grip_tape"), "deactivate should accept a placed item")
	assert_almost_eq(
		_manager.get_stat(&"paddle_size"),
		base_size,
		0.01,
		"equipment on the rack should not affect stats",
	)
	assert_false(_manager.is_on_court("grip_tape"))

	# Re-placed on player → effect resumes at the same strength.
	assert_true(_manager.activate("grip_tape"))
	assert_almost_eq(
		_manager.get_stat(&"paddle_size"),
		placed_size,
		0.01,
		"re-placing should resume the same effect",
	)


# --- Ball lifecycle --------------------------------------------------------


# A ball on the rack has no influence on ball-speed stats. Dragging it onto
# the court registers its effect and marks it as on-court. Removing it from
# the court reverses both.
func test_ball_lifecycle_rack_court_rack() -> void:
	var base_min: float = _manager.get_stat(&"ball_speed_min")

	_manager.take("training_ball")
	assert_almost_eq(
		_manager.get_stat(&"ball_speed_min"),
		base_min,
		0.01,
		"rack-resident ball must not affect ball stats",
	)
	assert_false(_manager.is_on_court("training_ball"))

	# Onto the court → in play and registered.
	assert_true(_manager.activate("training_ball"))
	assert_true(_manager.is_on_court("training_ball"), "activated ball should be on the court")
	assert_true(
		"training_ball" in _manager.get_court_items(),
		"court occupancy query should list the ball",
	)
	assert_gt(
		_manager.get_stat(&"ball_speed_min"),
		base_min,
		"ball on the court should register its effect",
	)

	# Back to rack → out of play and unregistered.
	assert_true(_manager.deactivate("training_ball"))
	assert_false(_manager.is_on_court("training_ball"))
	assert_false("training_ball" in _manager.get_court_items())
	assert_almost_eq(
		_manager.get_stat(&"ball_speed_min"),
		base_min,
		0.01,
		"ball back on the rack should stop affecting stats",
	)


# --- Level-up while placed -------------------------------------------------


# Purchasing another level while the item is on the player re-registers its
# effects at the new level without the player having to re-place it.
func test_level_up_while_equipment_on_player_updates_running_effects() -> void:
	var base_size: float = _manager.get_stat(&"paddle_size")

	_manager.take("grip_tape")
	_manager.activate("grip_tape")
	var size_at_l1: float = _manager.get_stat(&"paddle_size")

	_manager.purchase("grip_tape")
	assert_eq(_manager.get_level("grip_tape"), 2, "sanity: level advanced to 2")
	assert_true(_manager.is_on_court("grip_tape"), "level-up must not dislodge the item")

	var size_at_l2: float = _manager.get_stat(&"paddle_size")
	assert_gt(size_at_l2, size_at_l1, "level-up must update running effects on the player")
	assert_gt(size_at_l2, base_size)


# A ball levelled while on the court sees its effect scale up live.
func test_level_up_while_ball_on_court_updates_running_effects() -> void:
	_manager.take("training_ball")
	_manager.activate("training_ball")
	var stat_at_l1: float = _manager.get_stat(&"ball_speed_min")

	_manager.purchase("training_ball")
	assert_eq(_manager.get_level("training_ball"), 2)
	assert_true(_manager.is_on_court("training_ball"), "ball stays on court across level-up")

	assert_gt(
		_manager.get_stat(&"ball_speed_min"),
		stat_at_l1,
		"level-up must update the ball's running effects on the court",
	)


# A level-up applied to a rack-resident item stays inert until it is placed.
func test_level_up_on_racked_item_does_not_start_effects() -> void:
	var base_size: float = _manager.get_stat(&"paddle_size")

	_manager.take("grip_tape")
	_manager.purchase("grip_tape")  # level 2, still on the rack.

	assert_eq(_manager.get_level("grip_tape"), 2)
	assert_false(_manager.is_on_court("grip_tape"))
	assert_almost_eq(
		_manager.get_stat(&"paddle_size"),
		base_size,
		0.01,
		"levels alone should not start effects while the item sits on the rack",
	)


# --- Save / reload round-trip ---------------------------------------------


# Placement is part of the saved progression: after a round-trip through
# storage into a fresh ItemManager, the same items are on the court and the
# same effects are running.
func test_save_and_reload_preserves_placement_and_effects() -> void:
	# Real ProgressionData-style storage round-trip: capture the JSON written
	# by save_to_disk() and hand it back on read().
	var captured_json: Array[String] = []
	var capturing_storage: SaveStorage = double(SaveStorage).new()
	stub(capturing_storage.write).to_do_nothing()
	stub(capturing_storage.read).to_return("")

	_manager._progression = ProgressionData.new(capturing_storage)
	_manager._progression.friendship_point_balance = 100000
	_manager._register_existing_items()

	# Place one equipment item and one ball; leave a third owned on the rack.
	_manager.take("grip_tape")
	_manager.activate("grip_tape")
	_manager.take("training_ball")
	_manager.activate("training_ball")
	_manager.take("ankle_weights")  # owned but never placed.

	var equipped_size: float = _manager.get_stat(&"paddle_size")
	var court_ball_min: float = _manager.get_stat(&"ball_speed_min")

	var saved_blob: String = JSON.stringify(_manager._progression.to_dict())

	# Fresh ItemManager + fresh ProgressionData, reading the saved blob.
	# Simulates a scene reload / process restart.
	var reload_storage: SaveStorage = double(SaveStorage).new()
	stub(reload_storage.write).to_return(true)
	stub(reload_storage.read).to_return(saved_blob)

	var reloaded: Node = load("res://scripts/items/item_manager.gd").new()  # gdlint:ignore = duplicated-load
	reloaded._progression = ProgressionData.new(reload_storage)
	assert_true(reloaded._progression.load_from_disk(), "reload must parse the saved blob")
	reloaded._effect_manager = EffectManager.new()
	reloaded.items.assign([GripTape, TrainingBall, AnkleWeights])
	add_child_autofree(reloaded)

	# Placement survives the round-trip.
	assert_true(reloaded.is_on_court("grip_tape"), "equipment placement must survive reload")
	assert_true(reloaded.is_on_court("training_ball"), "ball placement must survive reload")
	assert_false(
		reloaded.is_on_court("ankle_weights"),
		"rack-resident items must stay off-court after reload",
	)

	# Effects match what they were before the round-trip.
	assert_almost_eq(
		reloaded.get_stat(&"paddle_size"),
		equipped_size,
		0.01,
		"reloaded equipment must run the same effect",
	)
	assert_almost_eq(
		reloaded.get_stat(&"ball_speed_min"),
		court_ball_min,
		0.01,
		"reloaded ball must run the same effect",
	)

	# Rack items are still inert after reload — purchasing more levels must
	# not start the effect until the player places the item.
	var size_before_racked_purchase: float = reloaded.get_stat(&"paddle_size")
	reloaded.purchase("ankle_weights")
	assert_almost_eq(
		reloaded.get_stat(&"paddle_size"),
		size_before_racked_purchase,
		0.01,
		"levels on a racked item stay inert after reload",
	)
