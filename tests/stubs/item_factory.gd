class_name ItemFactory
extends RefCounted

const ItemManagerScript := preload("res://scripts/items/item_manager.gd")


static func create_manager(
	gut_test: GutTest,
	item_key: String = "test_speed",
	stat_key: StringName = &"paddle_speed",
	operation: StringName = &"add",
	value: float = 50.0,
) -> Node:
	var item := create(item_key, stat_key, operation, value)
	var manager: Node = ItemManagerScript.new()
	manager.state = ItemState.new()
	manager.economy = EconomyState.new()
	manager._effect_manager = EffectManager.new()
	manager.items.assign([item])
	gut_test.add_child_autofree(manager)
	return manager


static func create(
	item_key: String, stat_key: StringName, operation: StringName, value: float
) -> ItemDefinition:
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

	var item := ItemDefinition.new()
	item.key = item_key
	item.base_cost = 100
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = [effect]
	return item
