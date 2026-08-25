class_name BallFactory
extends RefCounted

const BallManagerScript := preload("res://scripts/items/ball_manager.gd")


static func create_manager(gut_test: GutTest, ball_key: String = "test_speed") -> Node:
	var item := create(ball_key)
	var manager: Node = BallManagerScript.new()
	manager._state = BallState.new()
	manager.economy = EconomyState.new()
	manager.items.assign([item])
	gut_test.add_child_autofree(manager)
	return manager


## Gives the test manager an owned item at `level`, placed STORED.
## Replaces the `state.ball_levels[key] = 1` poke that bypasses placement seams.
static func give(manager: Node, ball_key: String, level: int = 1) -> void:
	manager._state.ball_levels[ball_key] = level
	manager._set_item_placement(ball_key, Placement.STORED)


static func create(ball_key: String) -> BallDefinition:
	var item := BallDefinition.new()
	item.key = ball_key
	item.base_cost = 100
	item.cost_scaling = 2.0
	item.max_level = 3
	item.scene = load("res://scenes/balls/ball.tscn")
	return item
