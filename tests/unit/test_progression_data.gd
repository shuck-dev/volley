extends GutTest

var _data: ProgressionData
var _mock_storage: SaveStorage


func before_each() -> void:
	_mock_storage = double(SaveStorage).new()
	_data = ProgressionData.new(_mock_storage)


# --- save_to_disk / load_from_disk ---
func test_save_to_disk_returns_true() -> void:
	_data.friendship_point_balance = 100
	stub(_mock_storage.write).to_return(true)
	assert_true(_data.save_to_disk())


func test_save_to_disk_returns_false_on_failure() -> void:
	stub(_mock_storage.write).to_return(false)
	assert_false(_data.save_to_disk())


func test_load_from_disk_returns_default_when_no_content() -> void:
	stub(_mock_storage.read).to_return("")
	_data.load_from_disk()
	assert_eq(_data.friendship_point_balance, 0)
	assert_eq(_data.item_levels, {} as Dictionary[String, int])
	assert_eq(_data.personal_volley_best, 0)


func test_save_and_load_round_trip() -> void:
	_data.friendship_point_balance = 500
	_data.item_levels["paddle_speed"] = 3
	_data.personal_volley_best = 42

	var saved_json := JSON.stringify(_data.to_dict())
	stub(_mock_storage.write).to_return(true)
	_data.save_to_disk()

	var loaded := ProgressionData.new(_mock_storage)
	stub(_mock_storage.read).to_return(saved_json)
	loaded.load_from_disk()
	assert_eq(loaded.friendship_point_balance, 500)
	assert_eq(loaded.item_levels, {"paddle_speed": 3} as Dictionary[String, int])
	assert_eq(loaded.personal_volley_best, 42)


# --- to_dict ---
func test_default_values_return_vaild_dict() -> void:
	var result := _data.to_dict()
	assert_eq(result["friendship_point_balance"], 0)
	assert_eq(result["item_levels"], {})
	assert_eq(result["personal_volley_best"], 0)


func test_to_dict_with_modified_values() -> void:
	_data.friendship_point_balance = 500
	_data.item_levels["paddle_speed"] = 3
	_data.personal_volley_best = 42

	var result := _data.to_dict()
	assert_eq(result["friendship_point_balance"], 500)
	assert_eq(result["item_levels"], {"paddle_speed": 3})
	assert_eq(result["personal_volley_best"], 42)


# --- from_dict ---
func test_from_dict_round_trip() -> void:
	_data.friendship_point_balance = 250
	_data.item_levels["paddle_size"] = 2
	_data.personal_volley_best = 10

	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.friendship_point_balance, 250)
	assert_eq(restored.item_levels, {"paddle_size": 2})
	assert_eq(restored.personal_volley_best, 10)


func test_from_dict_missing_keys_use_defaults() -> void:
	var restored := ProgressionData.from_dict({})
	assert_eq(restored.friendship_point_balance, 0)
	assert_eq(restored.item_levels, {})
	assert_eq(restored.personal_volley_best, 0)


# --- total_friendship_points_earned ---
func test_total_friendship_points_earned_default_zero() -> void:
	assert_eq(_data.total_friendship_points_earned, 0)


func test_total_friendship_points_earned_round_trips() -> void:
	_data.total_friendship_points_earned = 1234
	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.total_friendship_points_earned, 1234)


func test_clear_resets_total_friendship_points_earned() -> void:
	_data.total_friendship_points_earned = 500
	_data.clear()
	assert_eq(_data.total_friendship_points_earned, 0)


# --- partner fields ---
func test_partner_fields_default_empty() -> void:
	assert_eq(_data.unlocked_partners, [] as Array[StringName])
	assert_eq(_data.active_partner, &"")
	assert_eq(_data.partner_volley_totals, {} as Dictionary[StringName, int])


func test_partner_fields_round_trip() -> void:
	_data.unlocked_partners = [&"martha"] as Array[StringName]
	_data.active_partner = &"martha"
	_data.partner_volley_totals = {&"martha": 150} as Dictionary[StringName, int]

	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.unlocked_partners, [&"martha"] as Array[StringName])
	assert_eq(restored.active_partner, "martha")
	assert_eq(restored.partner_volley_totals, {&"martha": 150} as Dictionary[StringName, int])


func test_partner_fields_missing_from_dict_use_defaults() -> void:
	var restored := ProgressionData.from_dict({})
	assert_eq(restored.unlocked_partners, [] as Array[StringName])
	assert_eq(restored.active_partner, &"")
	assert_eq(restored.partner_volley_totals, {} as Dictionary[StringName, int])


func test_clear_resets_partner_fields() -> void:
	_data.unlocked_partners = [&"martha"] as Array[StringName]
	_data.active_partner = &"martha"
	_data.partner_volley_totals = {&"martha": 150} as Dictionary[StringName, int]
	_data.clear()
	assert_eq(_data.unlocked_partners, [] as Array[StringName])
	assert_eq(_data.active_partner, &"")
	assert_eq(_data.partner_volley_totals, {} as Dictionary[StringName, int])


func test_partner_save_and_load_round_trip() -> void:
	_data.unlocked_partners = [&"martha"] as Array[StringName]
	_data.active_partner = &"martha"
	_data.partner_volley_totals = {&"martha": 500} as Dictionary[StringName, int]

	var saved_json := JSON.stringify(_data.to_dict())
	stub(_mock_storage.write).to_return(true)
	_data.save_to_disk()

	var loaded := ProgressionData.new(_mock_storage)
	stub(_mock_storage.read).to_return(saved_json)
	loaded.load_from_disk()
	assert_eq(loaded.unlocked_partners, [&"martha"] as Array[StringName])
	assert_eq(loaded.active_partner, "martha")
	assert_eq(loaded.partner_volley_totals, {&"martha": 500} as Dictionary[StringName, int])
