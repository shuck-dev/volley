extends GutTest

# Position, rack-slot, and loose-body persistence on ItemWorldState.
# Vector2 has no native JSON representation, so the {"x", "y"} nesting must
# survive stringify+parse.

var _data: ItemWorldState


func before_each() -> void:
	_data = ItemWorldState.new()


func test_item_positions_default_empty() -> void:
	assert_eq(_data.item_positions, {} as Dictionary[String, Vector2])


func test_item_positions_round_trip_via_dict() -> void:
	_data.item_positions["base_ball"] = Vector2(123.5, -42.0)
	_data.item_positions["training_ball"] = Vector2(0.0, 0.0)
	var restored := ItemWorldState.new()
	restored.apply_save_dict(_data.to_save_dict())
	assert_eq(restored.item_positions["base_ball"], Vector2(123.5, -42.0))
	assert_eq(restored.item_positions["training_ball"], Vector2.ZERO)


func test_item_positions_survives_json_string_round_trip() -> void:
	_data.item_positions["base_ball"] = Vector2(640.25, 360.75)
	var saved_json := JSON.stringify(_data.to_save_dict())
	var loaded := ItemWorldState.new()
	loaded.apply_save_dict(JSON.parse_string(saved_json))
	assert_eq(loaded.item_positions["base_ball"], Vector2(640.25, 360.75))


func test_item_positions_missing_key_defaults_empty() -> void:
	var restored := ItemWorldState.new()
	restored.apply_save_dict({})
	assert_eq(restored.item_positions, {} as Dictionary[String, Vector2])


func test_loose_in_venue_round_trips() -> void:
	_data.loose_in_venue = ["spare"] as Array[String]
	var restored := ItemWorldState.new()
	restored.apply_save_dict(_data.to_save_dict())
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
	var restored := ItemWorldState.new()
	restored.apply_save_dict(_data.to_save_dict())
	assert_eq(restored.rack_slot_index_by_key["base_ball"], 0)
	assert_eq(restored.rack_slot_index_by_key["training_ball"], 2)


func test_rack_slot_index_by_key_survives_json_string_round_trip() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 1
	var saved_json := JSON.stringify(_data.to_save_dict())
	var loaded := ItemWorldState.new()
	loaded.apply_save_dict(JSON.parse_string(saved_json))
	assert_eq(loaded.rack_slot_index_by_key["base_ball"], 1)


func test_rack_slot_index_by_key_missing_defaults_empty() -> void:
	var restored := ItemWorldState.new()
	restored.apply_save_dict({})
	assert_eq(restored.rack_slot_index_by_key, {} as Dictionary[String, int])


func test_clear_resets_rack_slot_index() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 3
	_data.clear()
	assert_eq(_data.rack_slot_index_by_key, {} as Dictionary[String, int])
