class_name ProgressionManagerFactory
extends RefCounted

const ProgressionManagerScript := preload("res://scripts/progression/progression_manager.gd")


static func create_manager(gut_test: GutTest, item_manager: Node) -> Node:
	var progression_manager: Node = ProgressionManagerScript.new()
	progression_manager._progression = item_manager._progression
	item_manager.friendship_point_balance_changed.connect(
		progression_manager._on_friendship_point_balance_changed
	)
	gut_test.add_child_autofree(progression_manager)
	return progression_manager
