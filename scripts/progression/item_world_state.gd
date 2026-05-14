class_name ItemWorldState
extends RefCounted

var item_levels: Dictionary[String, int] = {}
var item_placements: Dictionary[String, int] = {}

## Per-item world position; balls and loose bodies reload where the player left them.
var item_positions: Dictionary[String, Vector2] = {}

## Rack slot index per STORED item; rack owns the slot→world mapping.
var rack_slot_index_by_key: Dictionary[String, int] = {}

## Keys of items currently dropped on the venue floor; survives the session so
## loose bodies respawn rather than vanishing back to the rack.
var loose_in_venue: Array[String] = []


func clear() -> void:
	item_levels = {}
	item_placements = {}
	item_positions = {}
	rack_slot_index_by_key = {}
	loose_in_venue = []


func to_save_dict() -> Dictionary:
	return {
		"item_levels": item_levels,
		"item_placements": item_placements,
		"item_positions": _serialize_positions(item_positions),
		"rack_slot_index_by_key": rack_slot_index_by_key,
		"loose_in_venue": loose_in_venue,
	}


func apply_save_dict(data: Dictionary) -> void:
	item_levels = _to_typed_int_dict(data.get("item_levels", {}))
	item_placements = _to_typed_int_dict(data.get("item_placements", {}))
	item_positions = _parse_positions(data.get("item_positions", {}))
	rack_slot_index_by_key = _to_typed_int_dict(data.get("rack_slot_index_by_key", {}))
	loose_in_venue = _to_typed_string_array(data.get("loose_in_venue", []))


static func _to_typed_int_dict(raw: Dictionary) -> Dictionary[String, int]:
	var typed: Dictionary[String, int] = {}
	for key: String in raw:
		typed[key] = int(raw[key])
	return typed


static func _to_typed_string_array(raw: Array) -> Array[String]:
	var typed: Array[String] = []
	for value in raw:
		typed.append(str(value))
	return typed


## Vector2 has no native JSON representation; nest as {"x", "y"} floats so the
## round-trip survives stringify+parse without lossy string coercion.
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
