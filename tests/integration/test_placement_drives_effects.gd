extends GutTest

# Integration: placement drives effects.

const WristBrace: ItemDefinition = preload("res://resources/items/wrist_brace.tres")
const BaseBall: ItemDefinition = preload("res://resources/items/base_ball.tres")
const AnkleWeights: ItemDefinition = preload("res://resources/items/ankle_weights.tres")

var _manager: Node


func before_each() -> void:
	_manager = load("res://scripts/items/item_manager.gd").new()
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager._effect_manager = EffectManager.new()
	_manager.items.assign([WristBrace, BaseBall, AnkleWeights])
	_manager.economy.soul_balance = 100000
	add_child_autofree(_manager)


# --- Equipment lifecycle ---


# Taking an equipment item owns it but leaves it on the rack; no effect runs
func test_equipment_lifecycle_rack_player_rack_player() -> void:
	var base_speed: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager
	)

	# Take-only: owned, sitting on the gear rack. No effect.
	_manager.take("wrist_brace")
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager),
		base_speed,
		0.01,
		"rack-resident equipment must not affect stats",
	)
	assert_false(_manager.is_on_court("wrist_brace"), "take() should not place on player")

	# Placed on player: effect runs.
	assert_true(_manager.activate("wrist_brace"), "activate should accept an owned equipment item")
	var placed_speed: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager
	)
	assert_gt(placed_speed, base_speed, "equipment on player should register its effect")

	# Moved back to rack: effect stops.
	assert_true(_manager.deactivate("wrist_brace"), "deactivate should accept a placed item")
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager),
		base_speed,
		0.01,
		"equipment on the rack should not affect stats",
	)
	assert_false(_manager.is_on_court("wrist_brace"))

	# Re-placed on player: effect resumes at the same strength.
	assert_true(_manager.activate("wrist_brace"))
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager),
		placed_speed,
		0.01,
		"re-placing should resume the same effect",
	)


# --- Ball lifecycle --------


# A ball on the rack has no influence on ball-speed stats. Dragging it onto court registers it.
func test_ball_lifecycle_rack_court_rack() -> void:
	var base_min: float = Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager)

	_manager.take("base_ball")
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager),
		base_min,
		0.01,
		"rack-resident ball must not affect ball stats",
	)
	assert_false(_manager.is_on_court("base_ball"))

	# Onto the court: in play and registered.
	assert_true(_manager.activate("base_ball"))
	assert_true(_manager.is_on_court("base_ball"), "activated ball should be on the court")
	assert_true(
		"base_ball" in _manager.get_court_items(),
		"court occupancy query should list the ball",
	)
	assert_gt(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager),
		base_min,
		"ball on the court should register its effect",
	)

	# Back to rack: out of play and unregistered.
	assert_true(_manager.deactivate("base_ball"))
	assert_false(_manager.is_on_court("base_ball"))
	assert_false("base_ball" in _manager.get_court_items())
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", _manager),
		base_min,
		0.01,
		"ball back on the rack should stop affecting stats",
	)


# --- Save / reload round-trip ---


# Placement is part of the saved progression: after a round-trip through save-reload, placement and effects persist.
func test_save_and_reload_preserves_placement_and_effects() -> void:
	# Pure JSON round-trip on the items slice; exercises ItemManager re-hydration, not the storage seam.
	_manager.state = ItemState.new()
	_manager.economy = EconomyState.new()
	_manager.economy.soul_balance = 100000
	_manager._register_existing_items()

	# Place one equipment item and one ball; leave a third owned on the rack.
	_manager.take("wrist_brace")
	_manager.activate("wrist_brace")
	_manager.take("base_ball")
	_manager.activate("base_ball")
	_manager.take("ankle_weights")  # owned but never placed.

	var equipped_speed: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", _manager
	)
	var court_ball_min: float = Stats.resolve(
		GameRules.base.ball_speed_min, &"ball_speed_min", _manager
	)

	var saved_blob: String = JSON.stringify(_manager.state.to_save_dict())

	# Fresh ItemManager + fresh ItemState, hydrated from the saved blob.
	# Simulates a scene reload / process restart.
	var reloaded: Node = load("res://scripts/items/item_manager.gd").new()  # gdlint:ignore = duplicated-load
	reloaded.state = ItemState.new()
	reloaded.state.apply_save_dict(JSON.parse_string(saved_blob))
	reloaded.economy = EconomyState.new()
	reloaded._effect_manager = EffectManager.new()
	reloaded.items.assign([WristBrace, BaseBall, AnkleWeights])
	add_child_autofree(reloaded)

	# Placement survives the round-trip.
	assert_true(reloaded.is_on_court("wrist_brace"), "equipment placement must survive reload")
	assert_true(reloaded.is_on_court("base_ball"), "ball placement must survive reload")
	assert_false(
		reloaded.is_on_court("ankle_weights"),
		"rack-resident items must stay off-court after reload",
	)

	# Effects match what they were before the round-trip.
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", reloaded),
		equipped_speed,
		0.01,
		"reloaded equipment must run the same effect",
	)
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_min, &"ball_speed_min", reloaded),
		court_ball_min,
		0.01,
		"reloaded ball must run the same effect",
	)

	# Rack items are still inert after reload. Purchasing more levels must
	# not start the effect until the player places the item.
	var speed_before_racked_purchase: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", reloaded
	)
	reloaded.purchase("ankle_weights")
	assert_almost_eq(
		Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", reloaded),
		speed_before_racked_purchase,
		0.01,
		"levels on a racked item stay inert after reload",
	)
