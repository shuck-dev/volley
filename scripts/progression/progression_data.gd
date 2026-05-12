class_name ProgressionData
extends RefCounted

var friendship_point_balance := 0
var total_friendship_points_earned := 0
var item_levels: Dictionary[String, int] = {}
var item_placements: Dictionary[String, int] = {}
## Per-item world position; balls and loose bodies reload where the player left them.
var item_positions: Dictionary[String, Vector2] = {}
## Rack slot index per STORED item; rack owns the slot→world mapping. Production reader lands at step 7.5.
var rack_slot_index_by_key: Dictionary[String, int] = {}
## Keys of items currently dropped on the venue floor; survives the session so
## loose bodies respawn rather than vanishing back to the rack.
var loose_in_venue: Array[String] = []
var personal_volley_best := 0
var shop_unlocked := false
var recruit_offered_partners: Array[StringName] = []
var unlocked_partners: Array[StringName] = []
var active_partner: StringName = &""
var partner_volley_totals: Dictionary[StringName, int] = {}


## Resets progression fields to defaults; caller decides whether to persist.
func clear() -> void:
	friendship_point_balance = 0
	total_friendship_points_earned = 0
	item_levels = {}
	item_placements = {}
	item_positions = {}
	rack_slot_index_by_key = {}
	loose_in_venue = []
	personal_volley_best = 0
	shop_unlocked = false
	recruit_offered_partners = []
	unlocked_partners = []
	active_partner = &""
	partner_volley_totals = {}


## Parses the game data into a dictionary
func to_dict() -> Dictionary:
	return {
		"friendship_point_balance": friendship_point_balance,
		"total_friendship_points_earned": total_friendship_points_earned,
		"item_levels": item_levels,
		"item_placements": item_placements,
		"item_positions": _serialize_positions(item_positions),
		"rack_slot_index_by_key": rack_slot_index_by_key,
		"loose_in_venue": loose_in_venue,
		"personal_volley_best": personal_volley_best,
		"shop_unlocked": shop_unlocked,
		"recruit_offered_partners": recruit_offered_partners,
		"unlocked_partners": unlocked_partners,
		"active_partner": active_partner,
		"partner_volley_totals": partner_volley_totals,
	}


## Parses the game data dictionary into a [ProgressionData]
static func from_dict(data: Dictionary) -> ProgressionData:
	var progression := ProgressionData.new()
	progression.friendship_point_balance = data.get("friendship_point_balance", 0)
	progression.total_friendship_points_earned = data.get("total_friendship_points_earned", 0)
	progression.item_levels = _to_typed_dict(data.get("item_levels", {}))
	progression.item_placements = _to_typed_dict(data.get("item_placements", {}))
	progression.item_positions = _parse_positions(data.get("item_positions", {}))
	progression.rack_slot_index_by_key = _to_typed_dict(data.get("rack_slot_index_by_key", {}))
	progression.loose_in_venue = _to_typed_string_array(data.get("loose_in_venue", []))
	progression.personal_volley_best = data.get("personal_volley_best", 0)
	progression.shop_unlocked = data.get("shop_unlocked", false)
	progression.recruit_offered_partners = _to_typed_string_name_array(
		data.get("recruit_offered_partners", [])
	)
	progression.unlocked_partners = _to_typed_string_name_array(data.get("unlocked_partners", []))
	progression.active_partner = StringName(data.get("active_partner", ""))
	progression.partner_volley_totals = _to_typed_string_name_dict(
		data.get("partner_volley_totals", {})
	)

	return progression


static func _to_typed_string_name_array(raw: Array) -> Array[StringName]:
	var typed: Array[StringName] = []
	for value in raw:
		typed.append(StringName(str(value)))
	return typed


static func _to_typed_string_name_dict(raw: Dictionary) -> Dictionary[StringName, int]:
	var typed: Dictionary[StringName, int] = {}
	for key in raw:
		typed[StringName(str(key))] = int(raw[key])
	return typed


## Parsed untyped [Dictionary] into typed [Dictionary]
static func _to_typed_dict(raw: Dictionary) -> Dictionary[String, int]:
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
