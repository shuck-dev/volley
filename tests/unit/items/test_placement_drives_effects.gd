## SH-96 placement rule: effects run only on player or court, never on rack.
extends GutTest

const STAT_KEY := &"paddle_speed"
const BALL_STAT_KEY := &"ball_speed_min"
const EFFECT_VALUE := 50.0
const BALL_EFFECT_VALUE := 30.0


func _make_item(
	item_key: String,
	role: StringName,
	stat_key: StringName = STAT_KEY,
	value: float = EFFECT_VALUE,
) -> ItemDefinition:
	var outcome := StatOutcome.new()
	outcome.stat_key = stat_key
	outcome.operation = &"add"
	outcome.value = value

	var trigger := Trigger.new()
	trigger.type = &"always"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := ItemDefinition.new()
	item.key = item_key
	item.base_cost = 100
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = [effect]
	item.role = role
	return item


func _make_manager_with(items: Array) -> Node:
	var manager := ItemFactory.create_manager(self)
	var typed_items: Array[ItemDefinition] = []
	for item in items:
		typed_items.append(item)
	manager.items.assign(typed_items)
	return manager


func test_equipment_on_player_registers_effects_at_level() -> void:
	var item := _make_item("equip_a", &"equipment")
	var manager := _make_manager_with([item])
	manager._progression.item_levels[item.key] = 1
	var base_speed: float = GameRules.base_stats[STAT_KEY]
	manager.activate(item.key)
	assert_eq(
		manager.get_stat(STAT_KEY),
		base_speed + EFFECT_VALUE,
		"activating equipment on the player should register its effects",
	)


func test_removing_equipment_from_player_unregisters_effects() -> void:
	var item := _make_item("equip_b", &"equipment")
	var manager := _make_manager_with([item])
	manager._progression.item_levels[item.key] = 1
	manager.activate(item.key)
	var base_speed: float = GameRules.base_stats[STAT_KEY]
	manager.deactivate(item.key)
	assert_eq(
		manager.get_stat(STAT_KEY),
		base_speed,
		"deactivating equipment should unregister its effects",
	)


func test_ball_on_court_registers_effects_and_enters_play() -> void:
	var item := _make_item("ball_a", &"ball", BALL_STAT_KEY, BALL_EFFECT_VALUE)
	var manager := _make_manager_with([item])
	manager._progression.item_levels[item.key] = 1
	var base_value: float = GameRules.base_stats[BALL_STAT_KEY]
	watch_signals(manager)
	manager.activate(item.key)
	assert_eq(
		manager.get_stat(BALL_STAT_KEY),
		base_value + BALL_EFFECT_VALUE,
		"activating a ball on the court should register its effects",
	)
	assert_true(
		manager.is_on_court(item.key),
		"activated ball should be tracked as on the court",
	)
	assert_signal_emitted(
		manager,
		"court_changed",
		"court_changed should fire when a ball enters play",
	)


func test_removing_ball_from_court_unregisters_effects_and_leaves_play() -> void:
	var item := _make_item("ball_b", &"ball", BALL_STAT_KEY, BALL_EFFECT_VALUE)
	var manager := _make_manager_with([item])
	manager._progression.item_levels[item.key] = 1
	manager.activate(item.key)
	var base_value: float = GameRules.base_stats[BALL_STAT_KEY]
	watch_signals(manager)
	manager.deactivate(item.key)
	assert_eq(
		manager.get_stat(BALL_STAT_KEY),
		base_value,
		"deactivating a ball should unregister its effects",
	)
	assert_false(
		manager.is_on_court(item.key),
		"deactivated ball should no longer be tracked as on the court",
	)
	assert_signal_emitted(
		manager,
		"court_changed",
		"court_changed should fire when a ball leaves play",
	)


func test_items_on_a_rack_have_no_gameplay_effect() -> void:
	var equipment := _make_item("equip_rack", &"equipment")
	var ball := _make_item("ball_rack", &"ball", BALL_STAT_KEY, BALL_EFFECT_VALUE)
	var manager := _make_manager_with([equipment, ball])
	# Owned (i.e. sitting on the rack after purchase) but never activated.
	manager._progression.item_levels[equipment.key] = 1
	manager._progression.item_levels[ball.key] = 1
	var base_paddle: float = GameRules.base_stats[STAT_KEY]
	var base_ball: float = GameRules.base_stats[BALL_STAT_KEY]
	assert_eq(
		manager.get_stat(STAT_KEY),
		base_paddle,
		"owned but un-activated equipment should be inert on the rack",
	)
	assert_eq(
		manager.get_stat(BALL_STAT_KEY),
		base_ball,
		"owned but un-activated balls should be inert on the rack",
	)
	assert_false(
		manager.is_on_court(equipment.key),
		"rack equipment should not be reported as on the court",
	)
	assert_false(
		manager.is_on_court(ball.key),
		"rack balls should not be reported as on the court",
	)


func test_levelling_equipment_on_player_updates_running_effects() -> void:
	var equipment := _make_item("equip_lvl", &"equipment")
	var manager := _make_manager_with([equipment])
	manager._progression.friendship_point_balance = 100000
	manager.purchase(equipment.key)
	manager.activate(equipment.key)
	var base_speed: float = GameRules.base_stats[STAT_KEY]
	assert_eq(
		manager.get_stat(STAT_KEY),
		base_speed + EFFECT_VALUE,
		"precondition: level 1 equipment grants one stack of its effect",
	)
	manager.purchase(equipment.key)
	assert_eq(
		manager.get_level(equipment.key),
		2,
		"precondition: purchase should raise the level to 2",
	)
	assert_eq(
		manager.get_stat(STAT_KEY),
		base_speed + 2.0 * EFFECT_VALUE,
		"levelling placed equipment should update its running effects",
	)


func test_levelling_ball_on_court_updates_running_effects() -> void:
	var ball := _make_item("ball_lvl", &"ball", BALL_STAT_KEY, BALL_EFFECT_VALUE)
	var manager := _make_manager_with([ball])
	manager._progression.friendship_point_balance = 100000
	manager.purchase(ball.key)
	manager.activate(ball.key)
	var base_value: float = GameRules.base_stats[BALL_STAT_KEY]
	assert_eq(
		manager.get_stat(BALL_STAT_KEY),
		base_value + BALL_EFFECT_VALUE,
		"precondition: level 1 ball grants one stack of its effect",
	)
	manager.purchase(ball.key)
	assert_eq(
		manager.get_stat(BALL_STAT_KEY),
		base_value + 2.0 * BALL_EFFECT_VALUE,
		"levelling a ball on the court should update its running effects",
	)
