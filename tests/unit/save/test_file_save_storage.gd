extends GutTest

# Exercises FileSaveStorage rotation + fallback with real files in user://.

const TEST_PATH := "user://test_save_data.json"
const BACKUP_1 := "user://test_save_data.1.json"
const BACKUP_2 := "user://test_save_data.2.json"
const BACKUP_3 := "user://test_save_data.3.json"

var _storage: FileSaveStorage


func before_each() -> void:
	_storage = FileSaveStorage.new(TEST_PATH)
	_remove_all()


func after_each() -> void:
	_remove_all()


# --- write / read ---
func test_write_creates_primary_file() -> void:
	assert_true(_storage.write("one"))
	assert_eq(_storage.read(), "one")


func test_read_returns_empty_when_no_file() -> void:
	assert_eq(_storage.read(), "")


# --- rolling backups ---
func test_second_write_moves_primary_to_backup_one() -> void:
	_storage.write("one")
	_storage.write("two")
	assert_eq(_storage.read(), "two")
	assert_eq(_read_raw(BACKUP_1), "one")


func test_third_write_shifts_backups() -> void:
	_storage.write("one")
	_storage.write("two")
	_storage.write("three")
	assert_eq(_storage.read(), "three")
	assert_eq(_read_raw(BACKUP_1), "two")
	assert_eq(_read_raw(BACKUP_2), "one")


func test_fourth_write_fills_all_three_backup_slots() -> void:
	_storage.write("one")
	_storage.write("two")
	_storage.write("three")
	_storage.write("four")
	assert_eq(_storage.read(), "four")
	assert_eq(_read_raw(BACKUP_1), "three")
	assert_eq(_read_raw(BACKUP_2), "two")
	assert_eq(_read_raw(BACKUP_3), "one")


func test_fifth_write_drops_oldest_backup() -> void:
	_storage.write("one")
	_storage.write("two")
	_storage.write("three")
	_storage.write("four")
	_storage.write("five")
	assert_eq(_storage.read(), "five")
	assert_eq(_read_raw(BACKUP_1), "four")
	assert_eq(_read_raw(BACKUP_2), "three")
	assert_eq(_read_raw(BACKUP_3), "two")
	assert_false(
		FileAccess.file_exists(
			BACKUP_3.get_basename().get_basename() + ".4." + BACKUP_3.get_extension()
		),
		"no fourth backup slot should exist",
	)


# --- read_fallbacks ---
func test_read_fallbacks_empty_when_no_backups() -> void:
	assert_eq(_storage.read_fallbacks(), [] as Array[String])


func test_read_fallbacks_returns_backups_newest_first() -> void:
	_storage.write("one")
	_storage.write("two")
	_storage.write("three")
	assert_eq(_storage.read_fallbacks(), ["two", "one"] as Array[String])


# --- fallback path via SaveManager ---
func test_save_manager_loads_from_backup_when_primary_corrupt() -> void:
	# Two writes so the valid JSON lands in backup slot 1; then trash primary
	# with empty content so SaveManager.load_from_disk() must fall through to
	# the backup chain to recover the last good state.
	var blob := '{"economy":{"friendship_point_balance":100}}'
	_storage.write(blob)
	_storage.write(blob)
	_write_raw(TEST_PATH, "")

	var save_manager: Node = load("res://scripts/progression/save_manager.gd").new(0.05)
	save_manager.set_storage(_storage)
	add_child_autofree(save_manager)
	assert_true(save_manager.load_from_disk())
	assert_eq(save_manager.economy.friendship_point_balance, 100)


# --- helpers ---
func _remove_all() -> void:
	for path in [TEST_PATH, BACKUP_1, BACKUP_2, BACKUP_3, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read_raw(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _write_raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()
