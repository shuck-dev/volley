class_name BallFactory
extends RefCounted

const BallManagerScript := preload("res://scripts/items/ball_manager.gd")


static func create_manager(
	gut_test: GutTest,
	ball_key: String = "test_speed",
	stat_key: StringName = &"paddle_speed",
	operation: StringName = &"add",
	value: float = 50.0,
) -> Node:
	var item := create(ball_key, stat_key, operation, value)
	var manager: Node = BallManagerScript.new()
	manager.state = BallState.new()
	manager.economy = EconomyState.new()
	manager._effect_manager = EffectManager.new()
	manager.items.assign([item])
	gut_test.add_child_autofree(manager)
	return manager


## Gives the test manager an owned item at `level`; assigns the rack slot when STORED.
## Replaces the `state.ball_levels[key] = 1` poke that bypasses placement seams.
static func give(manager: Node, ball_key: String, level: int = 1) -> void:
	manager.state.ball_levels[ball_key] = level
	manager._assign_rack_slot(ball_key)


static func create(
	ball_key: String, stat_key: StringName, operation: StringName, value: float
) -> BallDefinition:
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

	var item := BallDefinition.new()
	item.key = ball_key
	item.base_cost = 100
	item.cost_scaling = 2.0
	item.max_level = 3
	item.effects = [effect]
	item.scene = load("res://scenes/ball.tscn")
	return item
