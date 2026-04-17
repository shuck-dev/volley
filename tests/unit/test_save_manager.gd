extends GutTest

var _save_manager: Node
var _mock_storage: SaveStorage
var _progression: ProgressionData


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_progression = ProgressionData.new(_mock_storage)

	_save_manager = load("res://scripts/progression/save_manager.gd").new(0.05)
	_save_manager._progression = _progression
	add_child_autofree(_save_manager)


# --- get_progression_data ---
func test_get_progression_data_returns_injected_progression() -> void:
	assert_eq(_save_manager.get_progression_data(), _progression)


# --- save ---
func test_save_calls_write_on_storage() -> void:
	_save_manager.save()
	assert_called(_mock_storage, "write")


func test_save_writes_current_data_as_json() -> void:
	_progression.friendship_point_balance = 300
	_save_manager.save()
	var expected_json := JSON.stringify(_progression.to_dict())
	assert_called(_mock_storage, "write", [expected_json])


# --- autosave timer ---
func test_autosave_timer_triggers_save() -> void:
	await wait_seconds(0.2)
	assert_called(_mock_storage, "write")


# --- quit notification ---
func test_quit_notification_triggers_save() -> void:
	_save_manager.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_called(_mock_storage, "write")


# --- clear_save / write-guard ---
func test_clear_save_writes_cleared_state() -> void:
	_progression.friendship_point_balance = 500
	_save_manager.clear_save()
	var cleared_json := JSON.stringify(_progression.to_dict())
	assert_called(_mock_storage, "write", [cleared_json])


# clear_save writes once; a follow-up save() while blocked must not write again.
func test_save_is_noop_after_clear_save_until_unblocked() -> void:
	_save_manager.clear_save()
	_save_manager.save()
	assert_call_count(_mock_storage, "write", 1)


# clear_save writes once, then unblock + save writes a second time.
func test_unblock_writes_resumes_saves() -> void:
	_save_manager.clear_save()
	_save_manager.unblock_writes()
	_save_manager.save()
	assert_call_count(_mock_storage, "write", 2)


func test_clear_save_stops_autosave_timer() -> void:
	_save_manager.clear_save()
	assert_true(_save_manager._autosave_timer.is_stopped())


func test_unblock_writes_restarts_autosave_timer() -> void:
	_save_manager.clear_save()
	_save_manager.unblock_writes()
	assert_false(_save_manager._autosave_timer.is_stopped())


# If the autosave timer somehow fires while blocked (e.g. a deferred timeout
# queued before clear_save stopped it), the write guard must still suppress it.
func test_autosave_timeout_while_blocked_does_not_write() -> void:
	_save_manager.clear_save()
	_save_manager._autosave_timer.timeout.emit()
	assert_call_count(_mock_storage, "write", 1)
