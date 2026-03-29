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
	assert_eq(_data.upgrade_levels, {} as Dictionary[String, int])
	assert_eq(_data.personal_volley_best, 0)


func test_save_and_load_round_trip() -> void:
	_data.friendship_point_balance = 500
	_data.upgrade_levels["paddle_speed"] = 3
	_data.personal_volley_best = 42

	var saved_json := JSON.stringify(_data.to_dict())
	stub(_mock_storage.write).to_return(true)
	_data.save_to_disk()

	var loaded := ProgressionData.new(_mock_storage)
	stub(_mock_storage.read).to_return(saved_json)
	loaded.load_from_disk()
	assert_eq(loaded.friendship_point_balance, 500)
	assert_eq(loaded.upgrade_levels, {"paddle_speed": 3} as Dictionary[String, int])
	assert_eq(loaded.personal_volley_best, 42)


# --- to_dict ---
func test_default_values_return_vaild_dict() -> void:
	var result := _data.to_dict()
	assert_eq(result["friendship_point_balance"], 0)
	assert_eq(result["upgrade_levels"], {})
	assert_eq(result["personal_volley_best"], 0)


func test_to_dict_with_modified_values() -> void:
	_data.friendship_point_balance = 500
	_data.upgrade_levels["paddle_speed"] = 3
	_data.personal_volley_best = 42

	var result := _data.to_dict()
	assert_eq(result["friendship_point_balance"], 500)
	assert_eq(result["upgrade_levels"], {"paddle_speed": 3})
	assert_eq(result["personal_volley_best"], 42)


# --- from_dict ---
func test_from_dict_round_trip() -> void:
	_data.friendship_point_balance = 250
	_data.upgrade_levels["paddle_size"] = 2
	_data.personal_volley_best = 10

	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.friendship_point_balance, 250)
	assert_eq(restored.upgrade_levels, {"paddle_size": 2})
	assert_eq(restored.personal_volley_best, 10)


func test_from_dict_missing_keys_use_defaults() -> void:
	var restored := ProgressionData.from_dict({})
	assert_eq(restored.friendship_point_balance, 0)
	assert_eq(restored.upgrade_levels, {})
	assert_eq(restored.personal_volley_best, 0)
