extends GutTest

# Tests for ProgressionData — save/load stubs for now, will cover real persistence in SH-31.

var _data: ProgressionData


func before_each() -> void:
	_data = ProgressionData.new()


func test_save_returns_true() -> void:
	assert_true(_data.save())


func test_load_returns_true() -> void:
	assert_true(_data.load())


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
