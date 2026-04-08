class_name ProgressionManagerFactory
extends RefCounted

const ProgressionManagerScript := preload("res://scripts/progression/progression_manager.gd")
const SaveManagerScript := preload("res://scripts/progression/save_manager.gd")


static func create_manager(gut_test: GutTest, item_manager: Node) -> Node:
	var progression_manager: Node = ProgressionManagerScript.new()
	progression_manager._progression = item_manager._progression
	progression_manager._item_manager = item_manager
	var mock_save_manager: Node = gut_test.double(SaveManagerScript).new()
	gut_test.stub(mock_save_manager.save).to_do_nothing()
	progression_manager._save_manager = mock_save_manager
	gut_test.add_child_autofree(progression_manager)
	return progression_manager
