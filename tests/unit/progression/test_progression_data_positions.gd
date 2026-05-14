extends GutTest

# Position, rack-slot, and loose-body persistence on ItemState.

var _data: ItemState


func before_each() -> void:
	_data = ItemState.new()


func test_ball_positions_default_empty() -> void:
	assert_eq(_data.ball_positions, {} as Dictionary[String, Vector2])


func test_ball_play_states_round_trips() -> void:
	_data.ball_play_states["base_ball"] = Ball.PlayState.OUT_REST
	_data.ball_play_states["training_ball"] = Ball.PlayState.PLAY_ARC
	var restored := ItemState.new()
	restored.apply_save_dict(_data.to_save_dict())
	assert_eq(restored.ball_play_states["base_ball"], int(Ball.PlayState.OUT_REST))
	assert_eq(restored.ball_play_states["training_ball"], int(Ball.PlayState.PLAY_ARC))


func test_ball_positions_round_trip_via_dict() -> void:
	_data.ball_positions["base_ball"] = Vector2(123.5, -42.0)
	_data.ball_positions["training_ball"] = Vector2(0.0, 0.0)
	var restored := ItemState.new()
	restored.apply_save_dict(_data.to_save_dict())
	assert_eq(restored.ball_positions["base_ball"], Vector2(123.5, -42.0))
	assert_eq(restored.ball_positions["training_ball"], Vector2.ZERO)


func test_ball_positions_survives_json_string_round_trip() -> void:
	_data.ball_positions["base_ball"] = Vector2(640.25, 360.75)
	var saved_json := JSON.stringify(_data.to_save_dict())
	var loaded := ItemState.new()
	loaded.apply_save_dict(JSON.parse_string(saved_json))
	assert_eq(loaded.ball_positions["base_ball"], Vector2(640.25, 360.75))


func test_ball_positions_missing_key_defaults_empty() -> void:
	var restored := ItemState.new()
	restored.apply_save_dict({})
	assert_eq(restored.ball_positions, {} as Dictionary[String, Vector2])


func test_loose_in_venue_round_trips_with_positions() -> void:
	_data.loose_in_venue["spare"] = Vector2(50.0, 75.0)
	var restored := ItemState.new()
	restored.apply_save_dict(_data.to_save_dict())
	assert_eq(restored.loose_in_venue["spare"], Vector2(50.0, 75.0))


func test_clear_resets_positions_and_loose_set() -> void:
	_data.ball_positions["base_ball"] = Vector2(100.0, 200.0)
	_data.loose_in_venue["spare"] = Vector2(10.0, 20.0)
	_data.clear()
	assert_eq(_data.ball_positions, {} as Dictionary[String, Vector2])
	assert_eq(_data.loose_in_venue, {} as Dictionary[String, Vector2])


func test_rack_slot_index_by_key_defaults_empty() -> void:
	assert_eq(_data.rack_slot_index_by_key, {} as Dictionary[String, int])


func test_rack_slot_index_by_key_round_trips() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 0
	_data.rack_slot_index_by_key["training_ball"] = 2
	var restored := ItemState.new()
	restored.apply_save_dict(_data.to_save_dict())
	assert_eq(restored.rack_slot_index_by_key["base_ball"], 0)
	assert_eq(restored.rack_slot_index_by_key["training_ball"], 2)


func test_rack_slot_index_by_key_survives_json_string_round_trip() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 1
	var saved_json := JSON.stringify(_data.to_save_dict())
	var loaded := ItemState.new()
	loaded.apply_save_dict(JSON.parse_string(saved_json))
	assert_eq(loaded.rack_slot_index_by_key["base_ball"], 1)


func test_rack_slot_index_by_key_missing_defaults_empty() -> void:
	var restored := ItemState.new()
	restored.apply_save_dict({})
	assert_eq(restored.rack_slot_index_by_key, {} as Dictionary[String, int])


func test_clear_resets_rack_slot_index() -> void:
	_data.rack_slot_index_by_key["base_ball"] = 3
	_data.clear()
	assert_eq(_data.rack_slot_index_by_key, {} as Dictionary[String, int])
