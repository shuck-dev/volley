class_name BallState
extends RefCounted

var ball_levels: Dictionary[String, int] = {}

## Placement enum per ball; every owned ball has exactly one entry, exactly one placement at a time.
var ball_placement: Dictionary[String, int] = {}

## Slot index per ball, meaningful only while STORED (rack slot) or IN_KIT (kit slot).
var ball_slot: Dictionary[String, int] = {}

## World position per ball, meaningful only while LOOSE_IN_VENUE.
var ball_venue_position: Dictionary[String, Vector2] = {}


func clear() -> void:
	ball_levels = {}
	ball_placement = {}
	ball_slot = {}
	ball_venue_position = {}


func to_save_dict() -> Dictionary:
	return {
		"ball_levels": ball_levels,
		"ball_placement": ball_placement,
		"ball_slot": ball_slot,
		"ball_venue_position": _serialize_positions(ball_venue_position),
	}


func apply_save_dict(data: Dictionary) -> void:
	ball_levels = _to_typed_int_dict(data.get("ball_levels", {}))
	ball_placement = _to_typed_int_dict(data.get("ball_placement", {}))
	ball_slot = _to_typed_int_dict(data.get("ball_slot", {}))
	ball_venue_position = _parse_positions(data.get("ball_venue_position", {}))


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
