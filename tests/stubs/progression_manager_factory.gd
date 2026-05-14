class_name ProgressionManagerFactory
extends RefCounted

const ProgressionManagerScript := preload("res://scripts/progression/progression_manager.gd")
const SaveManagerScript := preload("res://scripts/progression/save_manager.gd")


## Builds a ProgressionManager wired to the given ItemManager. Slices can be pre-seeded
## via the optional dict (e.g. {"unlocks": preset_unlocks}); missing slices default-init.
static func create_manager(
	gut_test: GutTest, item_manager: Node, slice_overrides: Dictionary = {}
) -> Node:
	var progression_manager: Node = ProgressionManagerScript.new()
	# Share economy with the item_manager so balance accrual is visible across both.
	progression_manager.economy = item_manager.economy
	progression_manager.records = slice_overrides.get("records", RecordsState.new())
	progression_manager.unlocks = slice_overrides.get("unlocks", UnlocksState.new())
	progression_manager.partners = slice_overrides.get("partners", PartnersState.new())
	progression_manager._item_manager = item_manager
	var mock_save_manager: Node = gut_test.double(SaveManagerScript).new()
	gut_test.stub(mock_save_manager.save).to_do_nothing()
	progression_manager._save_manager = mock_save_manager
	gut_test.add_child_autofree(progression_manager)
	return progression_manager
