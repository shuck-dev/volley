extends GutTest

var _data: ProgressionData


func before_each() -> void:
	_data = ProgressionData.new()


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
	_data.recruit_offered_partners = [&"martha"] as Array[StringName]

	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.unlocked_partners, [&"martha"] as Array[StringName])
	assert_eq(restored.active_partner, "martha")
	assert_eq(restored.partner_volley_totals, {&"martha": 150} as Dictionary[StringName, int])
	assert_eq(restored.recruit_offered_partners, [&"martha"] as Array[StringName])


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


# Cleared-state JSON round-trip stays here: the serialisation contract for empty
# partner fields is a ProgressionData concern, not a SaveManager concern.
func test_cleared_data_dict_round_trip_keeps_partner_fields_empty() -> void:
	_data.unlocked_partners = [&"martha"] as Array[StringName]
	_data.active_partner = &"martha"
	_data.partner_volley_totals = {&"martha": 500} as Dictionary[StringName, int]
	_data.clear()

	var cleared_json := JSON.stringify(_data.to_dict())
	var parsed: Variant = JSON.parse_string(cleared_json)
	var loaded := ProgressionData.from_dict(parsed)
	assert_eq(loaded.unlocked_partners, [] as Array[StringName])
	assert_eq(loaded.active_partner, &"")
	assert_eq(loaded.partner_volley_totals, {} as Dictionary[StringName, int])
