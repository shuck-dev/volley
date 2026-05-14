class_name ItemWorldState
extends RefCounted

var item_levels: Dictionary[String, int] = {}
var item_placements: Dictionary[String, int] = {}

## Last in-play position for every non-STORED ball; STORED reconstructs from rack_slot_index_by_key.
var ball_positions: Dictionary[String, Vector2] = {}

## PlayState enum per ball so OUT_REST does not re-enter court flow as PLAY_NORMAL on load.
var ball_play_states: Dictionary[String, int] = {}

## Rack slot index per STORED item; rack owns the slot→world mapping.
var rack_slot_index_by_key: Dictionary[String, int] = {}

## Loose drag-token items keyed by item key, value is their drop position.
var loose_in_venue: Dictionary[String, Vector2] = {}


func clear() -> void:
	item_levels = {}
	item_placements = {}
	ball_positions = {}
	ball_play_states = {}
	rack_slot_index_by_key = {}
	loose_in_venue = {}


func to_save_dict() -> Dictionary:
	return {
		"item_levels": item_levels,
		"item_placements": item_placements,
		"ball_positions": _serialize_positions(ball_positions),
		"ball_play_states": ball_play_states,
		"rack_slot_index_by_key": rack_slot_index_by_key,
		"loose_in_venue": _serialize_positions(loose_in_venue),
	}


func apply_save_dict(data: Dictionary) -> void:
	item_levels = _to_typed_int_dict(data.get("item_levels", {}))
	item_placements = _to_typed_int_dict(data.get("item_placements", {}))
	ball_positions = _parse_positions(data.get("ball_positions", {}))
	ball_play_states = _to_typed_int_dict(data.get("ball_play_states", {}))
	rack_slot_index_by_key = _to_typed_int_dict(data.get("rack_slot_index_by_key", {}))
	loose_in_venue = _parse_positions(data.get("loose_in_venue", {}))


static func _to_typed_int_dict(raw: Dictionary) -> Dictionary[String, int]:
	var typed: Dictionary[String, int] = {}

	for key: String in raw:
		typed[key] = int(raw[key])
	return typed


## Vector2 nested as {"x", "y"} floats so stringify+parse round-trips without lossy string coercion.
static func _serialize_positions(positions: Dictionary[String, Vector2]) -> Dictionary:
	var raw: Dictionary = {}

	for key: String in positions:
		var v: Vector2 = positions[key]
		raw[key] = {"x": v.x, "y": v.y}
	return raw


static func _parse_positions(raw: Dictionary) -> Dictionary[String, Vector2]:
	var typed: Dictionary[String, Vector2] = {}

	for key: String in raw:
		var entry: Variant = raw[key]

		if not entry is Dictionary:
			continue
		var dict: Dictionary = entry
		typed[key] = Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return typed
