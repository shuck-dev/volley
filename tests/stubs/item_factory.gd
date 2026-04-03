class_name ItemFactory
extends RefCounted


static func create(
	item_key: String, stat_key: StringName, operation: StatModifier.Operation, value: float
) -> ItemDefinition:
	var trigger := Trigger.new()
	trigger.type = &"always"

	var outcome := Outcome.new()
	outcome.type = &"modify_stat"
	outcome.parameters = {
		&"stat_key": stat_key,
		&"operation": operation,
		&"value": value,
	}

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
