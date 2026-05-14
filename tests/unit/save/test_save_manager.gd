extends GutTest

var _save_manager: Node
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	stub(_mock_storage.write).to_return(true)
	stub(_mock_storage.read).to_return("")

	_save_manager = load("res://scripts/progression/save_manager.gd").new(0.05)
	_save_manager.set_storage(_mock_storage)
	add_child_autofree(_save_manager)


# --- slice accessors ---
func test_slices_are_created_on_ready() -> void:
	assert_not_null(_save_manager.economy)
	assert_not_null(_save_manager.items)
	assert_not_null(_save_manager.records)
	assert_not_null(_save_manager.unlocks)
	assert_not_null(_save_manager.partners)


# --- save ---
func test_save_calls_write_on_storage() -> void:
	_save_manager.save()
	assert_called(_mock_storage, "write")


func test_save_writes_assembled_per_slice_json() -> void:
	_save_manager.economy.friendship_point_balance = 300
	_save_manager.save()
	var expected: Dictionary = {
		"economy": _save_manager.economy.to_save_dict(),
		"items": _save_manager.items.to_save_dict(),
		"records": _save_manager.records.to_save_dict(),
		"unlocks": _save_manager.unlocks.to_save_dict(),
		"partners": _save_manager.partners.to_save_dict(),
	}
	assert_called(_mock_storage, "write", [JSON.stringify(expected)])


# --- autosave timer ---
func test_autosave_timer_triggers_save() -> void:
	_save_manager._autosave_timer.timeout.emit()
	assert_called(_mock_storage, "write")


# --- quit notification ---
func test_quit_notification_triggers_save() -> void:
	_save_manager.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_called(_mock_storage, "write")


# --- clear_save / write-guard ---
func test_clear_save_resets_every_slice() -> void:
	_save_manager.economy.friendship_point_balance = 500
	_save_manager.unlocks.shop_unlocked = true
	_save_manager.partners.active_partner = &"martha"
	_save_manager.clear_save()
	assert_eq(_save_manager.economy.friendship_point_balance, 0)
	assert_false(_save_manager.unlocks.shop_unlocked)
	assert_eq(_save_manager.partners.active_partner, &"")


func test_save_is_noop_after_clear_save_until_unblocked() -> void:
	_save_manager.clear_save()
	_save_manager.save()
	assert_called_count(_mock_storage.write, 1)


func test_unblock_writes_resumes_saves() -> void:
	_save_manager.clear_save()
	_save_manager.unblock_writes()
	_save_manager.save()
	assert_called_count(_mock_storage.write, 2)


func test_clear_save_stops_autosave_timer() -> void:
	_save_manager.clear_save()
	assert_true(_save_manager._autosave_timer.is_stopped())


func test_unblock_writes_restarts_autosave_timer() -> void:
	_save_manager.clear_save()
	_save_manager.unblock_writes()
	assert_false(_save_manager._autosave_timer.is_stopped())


func test_autosave_timeout_while_blocked_does_not_write() -> void:
	_save_manager.clear_save()
	_save_manager._autosave_timer.timeout.emit()
	assert_called_count(_mock_storage.write, 1)


# --- position provider ---
func test_save_captures_positions_from_registered_provider() -> void:
	var live: Dictionary[String, Vector2] = {"base_ball": Vector2(50.0, 75.0)}
	_save_manager.set_position_provider(func() -> Dictionary[String, Vector2]: return live)
	_save_manager.save()
	assert_eq(_save_manager.items.ball_positions["base_ball"], Vector2(50.0, 75.0))


func test_save_without_provider_leaves_positions_untouched() -> void:
	_save_manager.items.ball_positions["base_ball"] = Vector2(1.0, 2.0)
	_save_manager.save()
	assert_eq(_save_manager.items.ball_positions["base_ball"], Vector2(1.0, 2.0))


# --- load_from_disk ---
func test_load_from_disk_applies_stored_blob() -> void:
	var blob_dict: Dictionary = {
		"economy": {"friendship_point_balance": 42, "total_friendship_points_earned": 100},
		"partners": {"active_partner": "martha"},
	}
	stub(_mock_storage.read).to_return(JSON.stringify(blob_dict))

	_save_manager.load_from_disk()

	assert_eq(_save_manager.economy.friendship_point_balance, 42)
	assert_eq(_save_manager.partners.active_partner, &"martha")


# Guards against a future refactor replacing slice instances instead of mutating in place.
# Multiple consumers (court, item_manager, progression_manager) cache slice refs;
# a replace would silently stale them.
func test_load_preserves_slice_instance_identity() -> void:
	var blob_dict: Dictionary = {
		"economy": {"friendship_point_balance": 99},
		"partners": {"active_partner": "reese"},
	}
	stub(_mock_storage.read).to_return(JSON.stringify(blob_dict))

	var held_economy: EconomyState = _save_manager.economy
	var held_partners: PartnersState = _save_manager.partners
	_save_manager.load_from_disk()

	assert_eq(held_economy, _save_manager.economy)
	assert_eq(held_partners, _save_manager.partners)
	assert_eq(held_economy.friendship_point_balance, 99)
	assert_eq(held_partners.active_partner, &"reese")
