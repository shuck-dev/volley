extends GutTest

# Position and loose-body persistence on ProgressionData.
# Vector2 has no native JSON representation, so the {"x", "y"} nesting must
# survive stringify+parse; older saves without the new keys must still load.

var _data: ProgressionData


func before_each() -> void:
	_data = ProgressionData.new()


func test_item_positions_default_empty() -> void:
	assert_eq(_data.item_positions, {} as Dictionary[String, Vector2])


func test_item_positions_round_trip_via_dict() -> void:
	_data.item_positions["base_ball"] = Vector2(123.5, -42.0)
	_data.item_positions["training_ball"] = Vector2(0.0, 0.0)
	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.item_positions["base_ball"], Vector2(123.5, -42.0))
	assert_eq(restored.item_positions["training_ball"], Vector2.ZERO)


func test_item_positions_survives_json_string_round_trip() -> void:
	_data.item_positions["base_ball"] = Vector2(640.25, 360.75)
	var saved_json := JSON.stringify(_data.to_dict())
	var loaded := ProgressionData.from_dict(JSON.parse_string(saved_json))
	assert_eq(loaded.item_positions["base_ball"], Vector2(640.25, 360.75))


func test_item_positions_missing_key_defaults_empty() -> void:
	# Backward compat: a save written before this field still loads cleanly.
	var legacy: Dictionary = {"friendship_point_balance": 50}
	var restored := ProgressionData.from_dict(legacy)
	assert_eq(restored.item_positions, {} as Dictionary[String, Vector2])
	assert_eq(restored.friendship_point_balance, 50)


func test_loose_in_venue_round_trips() -> void:
	_data.loose_in_venue = ["spare"] as Array[String]
	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.loose_in_venue, ["spare"] as Array[String])


func test_clear_resets_positions_and_loose_set() -> void:
	_data.item_positions["base_ball"] = Vector2(100.0, 200.0)
	_data.loose_in_venue = ["spare"] as Array[String]
	_data.clear()
	assert_eq(_data.item_positions, {} as Dictionary[String, Vector2])
	assert_eq(_data.loose_in_venue, [] as Array[String])


func test_rack_slot_index_by_key_defaults_empty() -> void:
	assert_eq(_data.rack_slot_index_by_key, {} as Dictionary[String, int])


func test_rack_slot_index_by_key_round_trips() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 0
	_data.rack_slot_index_by_key["training_ball"] = 2
	var restored := ProgressionData.from_dict(_data.to_dict())
	assert_eq(restored.rack_slot_index_by_key["base_ball"], 0)
	assert_eq(restored.rack_slot_index_by_key["training_ball"], 2)


func test_rack_slot_index_by_key_survives_json_string_round_trip() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 1
	var saved_json := JSON.stringify(_data.to_dict())
	var loaded := ProgressionData.from_dict(JSON.parse_string(saved_json))
	assert_eq(loaded.rack_slot_index_by_key["base_ball"], 1)


func test_rack_slot_index_by_key_missing_defaults_empty() -> void:
	var legacy: Dictionary = {"friendship_point_balance": 50}
	var restored := ProgressionData.from_dict(legacy)
	assert_eq(restored.rack_slot_index_by_key, {} as Dictionary[String, int])


func test_clear_resets_rack_slot_index() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 3
	_data.clear()
	assert_eq(_data.rack_slot_index_by_key, {} as Dictionary[String, int])
