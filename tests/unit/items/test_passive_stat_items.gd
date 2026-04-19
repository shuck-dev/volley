extends GutTest

# Verifies that all passive stat modifier items (always trigger + modify_stat outcome)
# load and apply correctly through the effect system.

var _items: Array[ItemDefinition] = [
	preload("res://resources/items/ankle_weights.tres"),
	preload("res://resources/items/training_ball.tres"),
	preload("res://resources/items/court_lines.tres"),
]

var _grip_tape: ItemDefinition = preload("res://resources/items/grip_tape.tres")
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
		return outcome.value * GameRules.base_stats[outcome.range_stat_key]
	return outcome.value


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
			manager.get_stat(stat),
			GameRules.base_stats[stat],
			"%s should not modify %s before purchase" % [item.key, stat],
		)


# --- applies at level one ---
func test_applies_stat_at_level_one() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		var delta := _value_per_level(item)
		manager._progression.friendship_point_balance = 100000
		manager.purchase(item.key)
		assert_almost_eq(
			manager.get_stat(stat),
			GameRules.base_stats[stat] + delta,
			0.01,
			"%s should add %s to %s at level 1" % [item.key, delta, stat],
		)


# --- stacks linearly ---
func test_stacks_linearly_across_levels() -> void:
	for item in _items:
		var manager := _create_manager(item)
		var stat := _stat_key(item)
		var delta := _value_per_level(item)
		manager._progression.friendship_point_balance = 100000
		manager.purchase(item.key)
		manager.purchase(item.key)
		manager.purchase(item.key)
		assert_almost_eq(
			manager.get_stat(stat),
			GameRules.base_stats[stat] + (delta * 3),
			0.01,
			"%s should stack linearly at level 3" % item.key,
		)


# --- percentage items ---
func test_grip_tape_increases_paddle_size_on_purchase() -> void:
	var manager := _create_manager(_grip_tape)
	manager._progression.friendship_point_balance = 100000
	manager.purchase(_grip_tape.key)
	assert_gt(
		manager.get_stat(&"paddle_size"),
		GameRules.base_stats[&"paddle_size"],
		"grip_tape should increase paddle_size above base",
	)


func test_grip_tape_grows_with_level() -> void:
	var manager := _create_manager(_grip_tape)
	manager._progression.friendship_point_balance = 100000
	manager.purchase(_grip_tape.key)
	var size_at_level_one: float = manager.get_stat(&"paddle_size")
	manager.purchase(_grip_tape.key)
	assert_gt(
		manager.get_stat(&"paddle_size"),
		size_at_level_one,
		"grip_tape should increase paddle_size further at higher levels",
	)


func test_equal_percentage_modifiers_cancel_out() -> void:
	var manager: Node = ItemFactory.create_manager(self, _grip_tape.key)
	manager.items.assign([_grip_tape, _wrist_brace])
	manager._progression.friendship_point_balance = 100000
	manager.purchase(_grip_tape.key)
	manager.purchase(_wrist_brace.key)
	assert_almost_eq(
		manager.get_stat(&"paddle_size"),
		GameRules.base_stats[&"paddle_size"],
		0.01,
		"equal percentage modifiers should cancel to base",
	)


# --- cursed item ---
func test_wrist_brace_has_negative_effect_value() -> void:
	var size_outcome: StatOutcome = _wrist_brace.effects[1].outcomes[0]
	assert_eq(size_outcome.stat_key, &"paddle_size")
	assert_lt(size_outcome.value, 0.0, "cursed effect should have a negative value")


func test_wrist_brace_reduces_paddle_size_on_purchase() -> void:
	var manager := _create_manager(_wrist_brace)
	manager._progression.friendship_point_balance = 100000
	manager.purchase(_wrist_brace.key)
	assert_lt(
		manager.get_stat(&"paddle_size"),
		GameRules.base_stats[&"paddle_size"],
		"wrist_brace should reduce paddle_size below base",
	)


func test_wrist_brace_increases_ball_speed_increment_on_purchase() -> void:
	var manager := _create_manager(_wrist_brace)
	manager._progression.friendship_point_balance = 100000
	manager.purchase(_wrist_brace.key)
	assert_gt(
		manager.get_stat(&"ball_speed_increment"),
		GameRules.base_stats[&"ball_speed_increment"],
		"wrist_brace should increase ball_speed_increment above base",
	)


func test_wrist_brace_cursed_penalty_scales_with_level() -> void:
	var manager := _create_manager(_wrist_brace)
	manager._progression.friendship_point_balance = 100000
	manager.purchase(_wrist_brace.key)
	var size_at_level_one: float = manager.get_stat(&"paddle_size")
	manager.purchase(_wrist_brace.key)
	var size_at_level_two: float = manager.get_stat(&"paddle_size")
	assert_lt(
		size_at_level_two,
		size_at_level_one,
		"cursed penalty should increase (paddle shrinks further) with level",
	)
