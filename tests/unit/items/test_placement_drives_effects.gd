## SH-96 placement rule: effects run only on the court, never on the rack.
extends GutTest

const STAT_KEY := &"ball_speed_min"
const EFFECT_VALUE := 30.0


func _make_item(item_key: String, value: float = EFFECT_VALUE) -> ItemDefinition:
	var outcome := StatOutcome.new()
	outcome.stat_key = STAT_KEY
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
	return item


func _make_manager_with(items: Array) -> Node:
	var manager: Node = ItemFactory.create_manager(self)
	var typed_items: Array[ItemDefinition] = []
	for item in items:
		typed_items.append(item)
	manager.items.assign(typed_items)
	return manager


func test_activating_on_court_registers_effects_and_enters_play() -> void:
	var item := _make_item("ball_a")
	var manager: Node = _make_manager_with([item])
	ItemFactory.give(manager, item.key)
	var base_value: float = GameRules.base.ball_speed_min
	watch_signals(manager)
	manager.activate(item.key)
	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_min, STAT_KEY, manager),
		base_value + EFFECT_VALUE,
		"activating an item on the court should register its effects",
	)
	assert_true(
		manager.is_on_court(item.key),
		"activated item should be tracked as on the court",
	)
	assert_signal_emitted(
		manager,
		"court_changed",
		"court_changed should fire when an item enters play",
	)


func test_removing_from_court_unregisters_effects_and_leaves_play() -> void:
	var item := _make_item("ball_b")
	var manager: Node = _make_manager_with([item])
	ItemFactory.give(manager, item.key)
	manager.activate(item.key)
	var base_value: float = GameRules.base.ball_speed_min
	watch_signals(manager)
	manager.deactivate(item.key)
	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_min, STAT_KEY, manager),
		base_value,
		"deactivating an item should unregister its effects",
	)
	assert_false(
		manager.is_on_court(item.key),
		"deactivated item should no longer be tracked as on the court",
	)
	assert_signal_emitted(
		manager,
		"court_changed",
		"court_changed should fire when an item leaves play",
	)


func test_removing_held_item_unregisters_effect_when_loose_overlay_set() -> void:
	var item := _make_item("held_item")
	var manager: Node = _make_manager_with([item])
	ItemFactory.give(manager, item.key)
	manager.activate(item.key)
	manager.mark_loose_in_venue(item.key)
	var base_value: float = GameRules.base.ball_speed_min

	manager.deactivate(item.key)

	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_min, STAT_KEY, manager),
		base_value,
		"removing a held item with the loose overlay set should unregister its effect",
	)
	assert_false(
		manager.is_loose_in_venue(item.key),
		"the STORED transition should clear the lingering loose-in-venue overlay",
	)


func test_items_on_a_rack_have_no_gameplay_effect() -> void:
	var item := _make_item("ball_rack")
	var manager: Node = _make_manager_with([item])
	# Owned (i.e. sitting on the rack after purchase) but never activated.
	ItemFactory.give(manager, item.key)
	var base_value: float = GameRules.base.ball_speed_min
	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_min, STAT_KEY, manager),
		base_value,
		"an owned but un-activated item should be inert on the rack",
	)
	assert_false(
		manager.is_on_court(item.key),
		"a racked item should not be reported as on the court",
	)


func test_levelling_a_placed_item_updates_running_effects() -> void:
	var item := _make_item("ball_lvl")
	var manager: Node = _make_manager_with([item])
	manager.economy.soul_balance = 100000
	manager.purchase(item.key)
	manager.activate(item.key)
	var base_value: float = GameRules.base.ball_speed_min
	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_min, STAT_KEY, manager),
		base_value + EFFECT_VALUE,
		"precondition: level 1 grants one stack of its effect",
	)
	manager.purchase(item.key)
	assert_eq(
		Stats.resolve(GameRules.base.ball_speed_min, STAT_KEY, manager),
		base_value + 2.0 * EFFECT_VALUE,
		"levelling a placed item should update its running effects",
	)
