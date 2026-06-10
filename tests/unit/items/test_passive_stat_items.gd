extends GutTest

# Verifies that all passive stat modifier items (always trigger + modify_stat outcome)
# load and apply correctly through the effect system.

var _items: Array[ItemDefinition] = [
	preload("res://resources/items/ankle_weights.tres"),
	preload("res://resources/items/training_ball.tres"),
]

var _wrist_brace: ItemDefinition = preload("res://resources/items/wrist_brace.tres")


func _create_manager(item: ItemDefinition) -> Node:
	var manager: Node = ItemFactory.create_manager(self, item.key)
	manager.items.assign([item])
	return manager


func _stat_key(item: ItemDefinition) -> StringName:
	var outcome: StatOutcome = item.effects[0].outcomes[0]
	return outcome.stat_key


func _value_per_level(item: ItemDefinition) -> float:
	var outcome: StatOutcome = item.effects[0].outcomes[0]
	if outcome.range_stat_key:
		return outcome.value * _base_value(outcome.range_stat_key)
	return outcome.value


# Bridge for tests that look up base values by key; production code uses typed config fields.
func _base_value(stat_key: StringName) -> float:
	var bases: Dictionary = GameRules.BASE_CONFIG.to_dict()
	bases.merge(GameRules.PADDLE_CONFIG.to_dict())
	return bases[stat_key]


# --- loads ---
func test_all_items_load_with_key_and_effects() -> void:
	for item in _items:
		assert_ne(item.key, "", "%s should have a key" % item.resource_path)
		assert_gt(item.effects.size(), 0, "%s should have effects" % item.key)


# --- no effect before purchase ---
func test_no_effect_before_purchase() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		assert_eq(
			Stats.resolve(_base_value(stat), stat, manager),
			_base_value(stat),
			"%s should not modify %s before purchase" % [item.key, stat],
		)


# --- applies at level one ---
func test_applies_stat_at_level_one() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		var delta := _value_per_level(item)
		manager.economy.soul_balance = 100000
		manager.purchase(item.key)
		manager.activate(item.key)
		assert_almost_eq(
			Stats.resolve(_base_value(stat), stat, manager),
			_base_value(stat) + delta,
			0.01,
			"%s should add %s to %s at level 1" % [item.key, delta, stat],
		)


# --- stacks linearly ---
func test_stacks_linearly_across_levels() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		var delta := _value_per_level(item)
		manager.economy.soul_balance = 100000
		manager.purchase(item.key)
		manager.activate(item.key)
		manager.purchase(item.key)
		manager.activate(item.key)
		manager.purchase(item.key)
		manager.activate(item.key)
		assert_almost_eq(
			Stats.resolve(_base_value(stat), stat, manager),
			_base_value(stat) + (delta * 3),
			0.01,
			"%s should stack linearly at level 3" % item.key,
		)


# --- wrist brace single item ---
func test_wrist_brace_increases_ball_speed_increment_on_purchase() -> void:
	var manager := _create_manager(_wrist_brace)
	manager.economy.soul_balance = 100000
	manager.purchase(_wrist_brace.key)
	manager.activate(_wrist_brace.key)
	assert_gt(
		Stats.resolve(GameRules.base.ball_speed_increment, &"ball_speed_increment", manager),
		GameRules.base.ball_speed_increment,
		"wrist_brace should increase ball_speed_increment above base",
	)


func test_wrist_brace_speed_boost_scales_with_level() -> void:
	var manager := _create_manager(_wrist_brace)
	manager.economy.soul_balance = 100000
	manager.purchase(_wrist_brace.key)
	manager.activate(_wrist_brace.key)
	var speed_at_level_one: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", manager
	)
	manager.purchase(_wrist_brace.key)
	manager.activate(_wrist_brace.key)
	var speed_at_level_two: float = Stats.resolve(
		GameRules.base.ball_speed_increment, &"ball_speed_increment", manager
	)
	assert_gt(
		speed_at_level_two,
		speed_at_level_one,
		"speed boost should increase with level",
	)
