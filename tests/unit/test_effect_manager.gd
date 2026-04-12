extends GutTest

var _manager: EffectManager


func before_each() -> void:
	_manager = EffectManager.new()
	add_child_autofree(_manager)


func _make_item(item_key: String, effects: Array[Effect]) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.key = item_key
	item.max_level = 3
	item.effects = effects
	return item


func _make_always_modify_stat_effect(
	stat_key: StringName, operation: StringName, value: float
) -> Effect:
	var outcome := StatOutcome.new()
	outcome.stat_key = stat_key
	outcome.operation = operation
	outcome.value = value

	var trigger := Trigger.new()
	trigger.type = &"always"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1
	return effect


# --- base stats ---
func test_base_stat_values_are_registered_from_game_rules() -> void:
	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"])


# --- register_source ---
func test_register_source_applies_always_modify_stat_effect() -> void:
	var effect := _make_always_modify_stat_effect(&"paddle_speed", &"add", 50.0)
	var item := _make_item("test_item", [effect])

	_manager.register_source(item, 1)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] + 50.0)


func test_register_source_applies_multiply_effect() -> void:
	var effect := _make_always_modify_stat_effect(&"paddle_speed", &"multiply", 2.0)
	var item := _make_item("test_item", [effect])

	_manager.register_source(item, 1)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] * 2.0)


func test_register_source_ignores_effects_outside_level_range() -> void:
	var effect := _make_always_modify_stat_effect(&"paddle_speed", &"add", 50.0)
	effect.min_active_level = 2
	var item := _make_item("test_item", [effect])

	_manager.register_source(item, 1)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"])


func test_register_source_applies_multiple_effects() -> void:
	var effect_a := _make_always_modify_stat_effect(&"paddle_speed", &"add", 20.0)
	var effect_b := _make_always_modify_stat_effect(&"paddle_size", &"add", 10.0)
	var item := _make_item("test_item", [effect_a, effect_b])

	_manager.register_source(item, 1)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] + 20.0)
	assert_eq(_manager.get_stat(&"paddle_size"), GameRules.base_stats[&"paddle_size"] + 10.0)


func test_multiple_items_stack_modifiers() -> void:
	var effect_a := _make_always_modify_stat_effect(&"paddle_speed", &"add", 20.0)
	var effect_b := _make_always_modify_stat_effect(&"paddle_speed", &"add", 30.0)
	var item_a := _make_item("item_a", [effect_a])
	var item_b := _make_item("item_b", [effect_b])

	_manager.register_source(item_a, 1)
	_manager.register_source(item_b, 1)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] + 50.0)


# --- unregister_source ---
func test_unregister_source_removes_modifiers() -> void:
	var effect := _make_always_modify_stat_effect(&"paddle_speed", &"add", 50.0)
	var item := _make_item("test_item", [effect])

	_manager.register_source(item, 1)
	_manager.unregister_source(item)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"])


func test_unregister_source_keeps_other_items() -> void:
	var effect_a := _make_always_modify_stat_effect(&"paddle_speed", &"add", 20.0)
	var effect_b := _make_always_modify_stat_effect(&"paddle_speed", &"add", 30.0)
	var item_a := _make_item("item_a", [effect_a])
	var item_b := _make_item("item_b", [effect_b])

	_manager.register_source(item_a, 1)
	_manager.register_source(item_b, 1)
	_manager.unregister_source(item_a)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"] + 30.0)


# --- non-always triggers ---
func test_register_source_ignores_non_always_triggers() -> void:
	var outcome := StatOutcome.new()
	outcome.stat_key = &"paddle_speed"
	outcome.operation = &"add"
	outcome.value = 50.0

	var trigger := Trigger.new()
	trigger.type = &"on_hit"

	var effect := Effect.new()
	effect.trigger = trigger
	effect.outcomes = [outcome]
	effect.min_active_level = 1

	var item := _make_item("test_item", [effect])
	_manager.register_source(item, 1)

	assert_eq(_manager.get_stat(&"paddle_speed"), GameRules.base_stats[&"paddle_speed"])
