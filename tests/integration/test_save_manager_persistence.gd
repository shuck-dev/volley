## Drives a real SaveManager against real files in user:// through save, clear, and load,
## the orchestration layer that ties slice state to disk (not covered by the pure
## FileSaveStorage rotation tests or the per-slice to_save_dict round-trips).
extends GutTest

const SaveManagerScript: GDScript = preload("res://scripts/progression/save_manager.gd")

const TEST_PATH := "user://test_save_manager_data.json"
const BACKUP_1 := "user://test_save_manager_data.1.json"
const BACKUP_2 := "user://test_save_manager_data.2.json"
const BACKUP_3 := "user://test_save_manager_data.3.json"

var _save_manager: Node


func before_each() -> void:
	_remove_all()
	_save_manager = SaveManagerScript.new(0.05)
	_save_manager.set_storage(FileSaveStorage.new(TEST_PATH))
	add_child_autofree(_save_manager)


func after_each() -> void:
	_remove_all()


func test_save_persists_slice_state_to_disk() -> void:
	_save_manager.economy.soul_balance = 300
	_save_manager.save()

	var reloaded: Node = SaveManagerScript.new(0.05)
	reloaded.set_storage(FileSaveStorage.new(TEST_PATH))
	add_child_autofree(reloaded)

	assert_true(reloaded.load_from_disk())
	assert_eq(reloaded.economy.soul_balance, 300)


func test_autosave_timer_persists_state_without_manual_save() -> void:
	_save_manager.economy.soul_balance = 150
	_save_manager._autosave_timer.timeout.emit()

	var reloaded: Node = SaveManagerScript.new(0.05)
	reloaded.set_storage(FileSaveStorage.new(TEST_PATH))
	add_child_autofree(reloaded)

	assert_true(reloaded.load_from_disk())
	assert_eq(reloaded.economy.soul_balance, 150)


func test_clear_save_resets_every_slice_and_emits_save_cleared() -> void:
	_save_manager.economy.soul_balance = 500
	_save_manager.unlocks.shop_unlocked = true
	_save_manager.partners.active_partner = &"martha"
	watch_signals(_save_manager)

	_save_manager.clear_save()

	assert_eq(_save_manager.economy.soul_balance, 0)
	assert_false(_save_manager.unlocks.shop_unlocked)
	assert_eq(_save_manager.partners.active_partner, &"")
	assert_signal_emitted(_save_manager, "save_cleared")


func test_clear_save_blocks_further_writes_until_unblocked() -> void:
	_save_manager.clear_save()
	_save_manager.economy.soul_balance = 999
	_save_manager.save()

	var reloaded: Node = SaveManagerScript.new(0.05)
	reloaded.set_storage(FileSaveStorage.new(TEST_PATH))
	add_child_autofree(reloaded)

	assert_true(reloaded.load_from_disk())
	assert_eq(
		reloaded.economy.soul_balance, 0, "save() must no-op while writes are blocked by a clear"
	)


func test_unblock_writes_resumes_saving() -> void:
	_save_manager.clear_save()
	_save_manager.unblock_writes()
	_save_manager.economy.soul_balance = 42
	_save_manager.save()

	var reloaded: Node = SaveManagerScript.new(0.05)
	reloaded.set_storage(FileSaveStorage.new(TEST_PATH))
	add_child_autofree(reloaded)

	assert_true(reloaded.load_from_disk())
	assert_eq(reloaded.economy.soul_balance, 42)


func test_load_from_disk_falls_back_to_backup_when_primary_is_corrupt() -> void:
	var storage := FileSaveStorage.new(TEST_PATH)
	var blob := JSON.stringify({"economy": {"soul_balance": 100, "total_soul_earned": 100}})
	storage.write(blob)
	storage.write(blob)
	_write_raw(TEST_PATH, "")

	var reloaded: Node = SaveManagerScript.new(0.05)
	reloaded.set_storage(storage)
	add_child_autofree(reloaded)

	assert_true(reloaded.load_from_disk())
	assert_eq(reloaded.economy.soul_balance, 100)


func test_load_from_disk_mutates_slices_in_place_preserving_cached_references() -> void:
	var cached_economy: EconomyState = _save_manager.economy
	_save_manager.economy.soul_balance = 700
	_save_manager.save()

	_save_manager.economy.soul_balance = 0
	assert_true(_save_manager.load_from_disk())

	assert_same(
		_save_manager.economy,
		cached_economy,
		"slice identity must survive a reload for other systems' cached refs"
	)
	assert_eq(cached_economy.soul_balance, 700)


func _remove_all() -> void:
	for path in [TEST_PATH, BACKUP_1, BACKUP_2, BACKUP_3, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _write_raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()
